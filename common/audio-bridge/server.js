#!/usr/bin/env node
// WebSocket Audio Server
// Reads PCM data from stdin and broadcasts to connected clients

const WebSocket = require('ws');

// Parse command line arguments
const args = process.argv.slice(2);
const getArg = (name, defaultValue) => {
    const idx = args.indexOf(`--${name}`);
    return idx !== -1 && args[idx + 1] ? args[idx + 1] : defaultValue;
};

const PORT = parseInt(getArg('port', '6081'));
const SAMPLE_RATE = parseInt(getArg('rate', '22050'));
const CHANNELS = parseInt(getArg('channels', '2'));

// Create WebSocket server
const wss = new WebSocket.Server({ port: PORT });
const clients = new Set();

console.log(`Audio WebSocket server starting on port ${PORT}`);
console.log(`Audio config: ${SAMPLE_RATE}Hz, ${CHANNELS} channels, 16-bit PCM`);

wss.on('connection', (ws, req) => {
    const clientIP = req.socket.remoteAddress;
    clients.add(ws);
    console.log(`Client connected from ${clientIP}. Total clients: ${clients.size}`);
    
    // Send audio configuration
    ws.send(JSON.stringify({
        type: 'config',
        sampleRate: SAMPLE_RATE,
        channels: CHANNELS,
        encoding: '16bitInt'
    }));
    
    ws.on('close', () => {
        clients.delete(ws);
        console.log(`Client disconnected. Total clients: ${clients.size}`);
    });
    
    ws.on('error', (err) => {
        console.error('WebSocket error:', err.message);
        clients.delete(ws);
    });
});

wss.on('error', (err) => {
    console.error('Server error:', err.message);
});

// Read PCM data from stdin and broadcast
const CHUNK_SIZE = 4096; // Send in chunks for smoother playback
let buffer = Buffer.alloc(0);

process.stdin.on('data', (chunk) => {
    buffer = Buffer.concat([buffer, chunk]);
    
    // Send when we have enough data
    while (buffer.length >= CHUNK_SIZE) {
        const toSend = buffer.slice(0, CHUNK_SIZE);
        buffer = buffer.slice(CHUNK_SIZE);
        
        for (const client of clients) {
            if (client.readyState === WebSocket.OPEN) {
                try {
                    client.send(toSend);
                } catch (err) {
                    console.error('Send error:', err.message);
                    clients.delete(client);
                }
            }
        }
    }
});

process.stdin.on('end', () => {
    console.log('Audio stream ended');
    // Send remaining data
    if (buffer.length > 0) {
        for (const client of clients) {
            if (client.readyState === WebSocket.OPEN) {
                client.send(buffer);
            }
        }
    }
});

process.stdin.on('error', (err) => {
    console.error('Stdin error:', err.message);
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('Shutting down...');
    wss.close(() => {
        process.exit(0);
    });
});

process.on('SIGTERM', () => {
    console.log('Shutting down...');
    wss.close(() => {
        process.exit(0);
    });
});

console.log('Audio WebSocket server ready');
