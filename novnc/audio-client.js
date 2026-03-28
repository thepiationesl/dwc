/**
 * AudioStreamPlayer - Browser-side PCM audio player
 * Receives PCM data via WebSocket and plays using Web Audio API
 */
class AudioStreamPlayer {
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
     * @param {string} wsUrl - WebSocket URL (e.g., ws://localhost:6081)
     */
    connect(wsUrl) {
        if (this.ws) {
            this.ws.close();
        }
        
        console.log('Connecting to audio stream:', wsUrl);
        this.ws = new WebSocket(wsUrl);
        this.ws.binaryType = 'arraybuffer';
        
        this.ws.onopen = () => {
            console.log('Audio stream connected');
            this.connected = true;
            this.onConnect();
        };
        
        this.ws.onmessage = (event) => {
            if (typeof event.data === 'string') {
                // Configuration message
                try {
                    const config = JSON.parse(event.data);
                    if (config.type === 'config') {
                        console.log('Audio config received:', config);
                        this.sampleRate = config.sampleRate || this.sampleRate;
                        this.channels = config.channels || this.channels;
                    }
                } catch (e) {
                    console.error('Failed to parse config:', e);
                }
            } else {
                // PCM audio data
                if (this.audioCtx && !this.muted) {
                    this.feed(new Int16Array(event.data));
                }
            }
        };
        
        this.ws.onclose = () => {
            console.log('Audio stream disconnected');
            this.connected = false;
            this.onDisconnect();
        };
        
        this.ws.onerror = (error) => {
            console.error('Audio stream error:', error);
            this.onError(error);
        };
    }
    
    /**
     * Initialize Audio Context (must be called after user interaction)
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
            console.log('Audio context initialized, sample rate:', this.audioCtx.sampleRate);
            return true;
        } catch (e) {
            console.error('Failed to initialize audio context:', e);
            return false;
        }
    }
    
    /**
     * Feed PCM data to the player
     * @param {Int16Array} data - 16-bit PCM samples
     */
    feed(data) {
        if (!this.audioCtx || this.audioCtx.state !== 'running') {
            return;
        }
        
        // Convert Int16 to Float32
        const float32 = new Float32Array(data.length);
        for (let i = 0; i < data.length; i++) {
            float32[i] = data[i] / 32768.0;
        }
        this.samples.push(float32);
    }
    
    /**
     * Start the flush interval
     */
    startFlush() {
        if (this.interval) {
            clearInterval(this.interval);
        }
        this.interval = setInterval(() => this.flush(), this.flushingTime);
    }
    
    /**
     * Flush buffered samples to audio output
     */
    flush() {
        if (!this.samples.length || !this.audioCtx || this.audioCtx.state !== 'running') {
            return;
        }
        
        // Merge all buffered samples
        const totalLength = this.samples.reduce((sum, arr) => sum + arr.length, 0);
        if (totalLength === 0) return;
        
        const merged = new Float32Array(totalLength);
        let offset = 0;
        for (const arr of this.samples) {
            merged.set(arr, offset);
            offset += arr.length;
        }
        this.samples = [];
        
        // Create audio buffer
        const frameCount = Math.floor(merged.length / this.channels);
        if (frameCount === 0) return;
        
        try {
            const buffer = this.audioCtx.createBuffer(
                this.channels, 
                frameCount, 
                this.audioCtx.sampleRate
            );
            
            // De-interleave channels
            for (let ch = 0; ch < this.channels; ch++) {
                const channelData = buffer.getChannelData(ch);
                for (let i = 0; i < frameCount; i++) {
                    channelData[i] = merged[i * this.channels + ch] || 0;
                }
            }
            
            // Play the buffer
            const source = this.audioCtx.createBufferSource();
            source.buffer = buffer;
            source.connect(this.gainNode);
            source.start();
        } catch (e) {
            console.error('Audio playback error:', e);
        }
    }
    
    /**
     * Set volume (0.0 to 1.0)
     * @param {number} value - Volume level
     */
    setVolume(value) {
        const vol = Math.max(0, Math.min(1, value));
        this.lastVolume = vol;
        if (this.gainNode) {
            this.gainNode.gain.value = vol;
        }
    }
    
    /**
     * Get current volume
     * @returns {number} Current volume level
     */
    getVolume() {
        return this.gainNode ? this.gainNode.gain.value : 1;
    }
    
    /**
     * Mute/unmute audio
     * @param {boolean} muted - Mute state
     */
    setMuted(muted) {
        this.muted = muted;
        if (this.gainNode) {
            if (muted) {
                // Save current volume and set to zero
                this.lastVolume = this.gainNode.gain.value;
                this.gainNode.gain.value = 0;
            } else {
                // Restore saved volume
                this.gainNode.gain.value = this.lastVolume;
            }
        }
    }
    
    /**
     * Resume audio context (for browsers that suspend by default)
     */
    async resume() {
        if (this.audioCtx && this.audioCtx.state === 'suspended') {
            await this.audioCtx.resume();
            console.log('Audio context resumed');
        }
    }
    
    /**
     * Disconnect and cleanup
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
     * @returns {boolean}
     */
    static isSupported() {
        return !!(window.AudioContext || window.webkitAudioContext);
    }
}

// Create global instance
window.AudioStreamPlayer = AudioStreamPlayer;
window.audioPlayer = new AudioStreamPlayer();