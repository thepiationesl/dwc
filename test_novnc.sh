#!/bin/bash

echo "=== Testing noVNC Connection ==="

NOVNC_PORT=6180
VNC_INTERNAL_PORT=5901
HOST="localhost"
CONTAINER_NAME="dwc-desktop-audio-test"

echo ""
echo "1. Testing noVNC HTTP endpoint (port $NOVNC_PORT)..."
if curl -s -o /dev/null -w "%{http_code}" http://${HOST}:${NOVNC_PORT}/vnc.html | grep -q "200"; then
    echo "   [OK] noVNC web interface is accessible"
else
    echo "   [FAIL] noVNC web interface is not accessible"
fi

echo ""
echo "2. Testing VNC port (internal $VNC_INTERNAL_PORT)..."
if docker exec $CONTAINER_NAME ss -tlnp 2>/dev/null | grep -q ":${VNC_INTERNAL_PORT}"; then
    echo "   [OK] VNC port is listening"
else
    echo "   [FAIL] VNC port is not listening"
fi

echo ""
echo "3. Testing noVNC WebSocket connection..."
WS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://${HOST}:${NOVNC_PORT}/websockify)
if echo "$WS_RESPONSE" != "404"; then
    echo "   [OK] WebSocket endpoint responds"
else
    echo "   [INFO] WebSocket may require active VNC connection"
fi

echo ""
echo "4. Checking noVNC HTML content..."
if curl -s http://${HOST}:${NOVNC_PORT}/vnc.html | grep -q "noVNC"; then
    echo "   [OK] noVNC page content is valid"
else
    echo "   [FAIL] noVNC page content issue"
fi

echo ""
echo "5. Container processes..."
docker exec $CONTAINER_NAME ps aux | grep -E "(vnc|xfce|xvfb|novnc)" | grep -v grep || echo "   No matching processes found"

echo ""
echo "=== Test Complete ==="
echo "Access noVNC at: http://${HOST}:${NOVNC_PORT}/vnc.html"
echo "VNC password: 114514"
