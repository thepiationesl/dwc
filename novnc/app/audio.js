/**
 * AudioStreamPlayer - PCM Audio Player Module for noVNC
 * Receives PCM data via WebSocket and plays using Web Audio API
 */

/** @type {boolean} - Enable debug logging via localStorage: localStorage.setItem('DEBUG_AUDIO', 'true') */
const DEBUG_AUDIO = typeof localStorage !== 'undefined' &&
                   localStorage.getItem('DEBUG_AUDIO') === 'true';

// eslint-disable-next-line no-console
const log = DEBUG_AUDIO ? console.log.bind(console) : () => {};
// eslint-disable-next-line no-console
const error = DEBUG_AUDIO ? console.error.bind(console) : () => {};

export class AudioStreamPlayer {
    constructor(options = {}) {
        this.sampleRate = options.sampleRate || 22050;
        this.channels = options.channels || 2;
        this.flushingTime = options.flushingTime || 200;
        this.bufferSize = options.bufferSize || 256;

        this.audioCtx = null;
        this.gainNode = null;
        this.samples = [];
        this.interval = null;
        this.ws = null;
        this.connected = false;
        this.muted = false;
        this.lastVolume = 1;

        this.onConnect = options.onConnect || (() => {});
        this.onDisconnect = options.onDisconnect || (() => {});
        this.onError = options.onError || (() => {});
    }

    /**
     * Connect to audio WebSocket server
     */
    connect(wsUrl) {
        if (this.ws) {
            this.ws.close();
        }

        log('[Audio] Connecting to:', wsUrl);
        this.ws = new WebSocket(wsUrl);
        this.ws.binaryType = 'arraybuffer';

        this.ws.onopen = () => {
            log('[Audio] Connected');
            this.connected = true;
            this.onConnect();
        };

        this.ws.onmessage = (event) => {
            if (typeof event.data === 'string') {
                try {
                    const config = JSON.parse(event.data);
                    if (config.type === 'config') {
                        this.sampleRate = config.sampleRate || this.sampleRate;
                        this.channels = config.channels || this.channels;
                        log('[Audio] Config:', config);
                    }
                } catch (e) {
                    error('[Audio] Config parse error:', e);
                }
            } else {
                if (this.audioCtx && !this.muted) {
                    this.feed(new Int16Array(event.data));
                }
            }
        };

        this.ws.onclose = () => {
            log('[Audio] Disconnected');
            this.connected = false;
            this.onDisconnect();
        };

        this.ws.onerror = (wsError) => {
            error('[Audio] Error:', wsError);
            this.onError(wsError);
        };
    }

    /**
     * Initialize Audio Context (requires user interaction)
     */
    initAudioContext() {
        if (this.audioCtx) {
            return true;
        }

        try {
            this.audioCtx = new (window.AudioContext || window.webkitAudioContext)({
                sampleRate: this.sampleRate
            });

            this.gainNode = this.audioCtx.createGain();
            this.gainNode.gain.value = 1;
            this.gainNode.connect(this.audioCtx.destination);

            this.startFlush();
            log('[Audio] Context initialized, rate:', this.audioCtx.sampleRate);
            return true;
        } catch (e) {
            error('[Audio] Init error:', e);
            return false;
        }
    }

    /**
     * Feed PCM data
     */
    feed(data) {
        if (!this.audioCtx || this.audioCtx.state !== 'running') {
            return;
        }

        const float32 = new Float32Array(data.length);
        for (let i = 0; i < data.length; i++) {
            float32[i] = data[i] / 32768.0;
        }
        this.samples.push(float32);
    }

    /**
     * Start flush interval
     */
    startFlush() {
        if (this.interval) {
            clearInterval(this.interval);
        }
        this.interval = setInterval(() => this.flush(), this.flushingTime);
    }

    /**
     * Flush buffered samples
     */
    flush() {
        if (!this.samples.length || !this.audioCtx || this.audioCtx.state !== 'running') {
            return;
        }

        const totalLength = this.samples.reduce((sum, arr) => sum + arr.length, 0);
        if (totalLength === 0) return;

        const merged = new Float32Array(totalLength);
        let offset = 0;
        for (const arr of this.samples) {
            merged.set(arr, offset);
            offset += arr.length;
        }
        this.samples = [];

        const frameCount = Math.floor(merged.length / this.channels);
        if (frameCount === 0) return;

        try {
            const buffer = this.audioCtx.createBuffer(
                this.channels,
                frameCount,
                this.audioCtx.sampleRate
            );

            for (let ch = 0; ch < this.channels; ch++) {
                const channelData = buffer.getChannelData(ch);
                for (let i = 0; i < frameCount; i++) {
                    channelData[i] = merged[i * this.channels + ch] || 0;
                }
            }

            const source = this.audioCtx.createBufferSource();
            source.buffer = buffer;
            source.connect(this.gainNode);
            source.start(0);
        } catch (e) {
            error('[Audio] Playback error:', e);
        }
    }

    /**
     * Set volume (0.0 to 1.0)
     */
    setVolume(value) {
        const vol = Math.max(0, Math.min(1, value));
        this.lastVolume = vol;
        if (this.gainNode) {
            this.gainNode.gain.value = this.muted ? 0 : vol;
        }
    }

    /**
     * Get current volume
     */
    getVolume() {
        return this.gainNode ? this.gainNode.gain.value : 1;
    }

    /**
     * Toggle mute
     */
    toggleMute() {
        this.muted = !this.muted;
        if (this.gainNode) {
            this.gainNode.gain.value = this.muted ? 0 : this.lastVolume;
        }
        return this.muted;
    }

    /**
     * Set mute state
     */
    setMuted(muted) {
        this.muted = muted;
        if (this.gainNode) {
            this.gainNode.gain.value = muted ? 0 : this.lastVolume;
        }
    }

    /**
     * Resume suspended audio context
     */
    async resume() {
        if (this.audioCtx && this.audioCtx.state === 'suspended') {
            await this.audioCtx.resume();
            log('[Audio] Resumed');
        }
    }

    /**
     * Destroy player
     */
    destroy() {
        if (this.interval) {
            clearInterval(this.interval);
            this.interval = null;
        }

        if (this.ws) {
            this.ws.close();
            this.ws = null;
        }

        if (this.audioCtx) {
            this.audioCtx.close();
            this.audioCtx = null;
        }

        this.samples = [];
        this.connected = false;
    }

    /**
     * Check if audio is supported
     */
    static isSupported() {
        return !!(window.AudioContext || window.webkitAudioContext);
    }
}

export default AudioStreamPlayer;
