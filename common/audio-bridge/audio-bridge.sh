#!/bin/bash
# Audio Bridge: PulseAudio -> WebSocket
# Captures PulseAudio output and streams PCM data via WebSocket

AUDIO_PORT="${AUDIO_PORT:-6081}"
SAMPLE_RATE="${AUDIO_SAMPLE_RATE:-22050}"
CHANNELS="${AUDIO_CHANNELS:-2}"

# Ensure PulseAudio is running
pulseaudio --check || pulseaudio --start --exit-idle-time=-1

# Wait for PulseAudio to be ready
sleep 2

# Find the monitor source
MONITOR=$(pactl list short sources | grep monitor | head -1 | cut -f2)
if [ -z "$MONITOR" ]; then
    echo "No monitor source found, creating null sink..."
    pactl load-module module-null-sink sink_name=auto_null sink_properties=device.description="Audio_Bridge"
    MONITOR="auto_null.monitor"
fi

echo "Using monitor source: $MONITOR"
echo "Starting audio bridge on port $AUDIO_PORT..."

# GStreamer pipeline: PulseAudio -> PCM -> WebSocket
exec gst-launch-1.0 -q \
    pulsesrc device="$MONITOR" \
    ! audioconvert \
    ! audioresample \
    ! "audio/x-raw,format=S16LE,rate=$SAMPLE_RATE,channels=$CHANNELS" \
    ! fdsink fd=1 \
    | node /opt/audio-bridge/server.js --port "$AUDIO_PORT" --rate "$SAMPLE_RATE" --channels "$CHANNELS"
