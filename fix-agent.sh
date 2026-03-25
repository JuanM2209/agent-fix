#!/bin/bash
# Nucleus Agent Reinstall v0.18.0
# Downloads from GitHub releases and installs with correct DEVICE_ID from factory file
# Usage: curl -sL https://raw.githubusercontent.com/JuanM2209/agent-fix/master/fix-agent.sh | bash

set -e

RELEASE_URL="https://github.com/JuanM2209/nucleus-agent-releases/releases/download/v0.18.0/nucleus-agent-r18.tar.gz"
IMAGE_NAME="nucleus-agent:r18"
CONTAINER_NAME="remote-s"
FACTORY_FILE="/data/nucleus/factory/nucleus_serial_number"
CONTROL_PLANE="wss://api.datadesng.com/ws/agent"

echo "=== Nucleus Agent v0.18.0 Reinstall ==="
echo ""

# 1. Read device serial from factory file
echo "[1/6] Reading device serial..."
if [ -f "$FACTORY_FILE" ]; then
  DEVICE_SERIAL=$(cat "$FACTORY_FILE" | tr -d '[:space:]')
  echo "  -> Serial: $DEVICE_SERIAL"
else
  echo "  ERROR: Factory file not found at $FACTORY_FILE"
  echo "  Please enter device serial manually:"
  read -r DEVICE_SERIAL
fi

# 2. Stop and remove ALL agent containers (old and new)
echo ""
echo "[2/6] Cleaning up old containers..."
for c in remote-s remote-s-backup remote-support; do
  if docker ps -a --format '{{.Names}}' | grep -q "^${c}$"; then
    echo "  Stopping $c..."
    docker stop "$c" 2>/dev/null || true
    docker rm "$c" 2>/dev/null || true
    echo "  -> Removed $c"
  fi
done

# 3. Remove old image
echo ""
echo "[3/6] Removing old image..."
docker rmi "$IMAGE_NAME" 2>/dev/null || true

# 4. Download fresh image from GitHub releases
echo ""
echo "[4/6] Downloading $IMAGE_NAME from GitHub releases..."
curl -sL "$RELEASE_URL" -o /tmp/nucleus-agent-r18.tar.gz
echo "  -> Downloaded $(du -h /tmp/nucleus-agent-r18.tar.gz | cut -f1)"

# 5. Load image
echo ""
echo "[5/6] Loading Docker image..."
docker load -i /tmp/nucleus-agent-r18.tar.gz
rm -f /tmp/nucleus-agent-r18.tar.gz

# 6. Create and start container
echo ""
echo "[6/6] Creating container..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --hostname "$DEVICE_SERIAL" \
  --network host \
  --restart unless-stopped \
  --privileged \
  -v /dev:/dev \
  -v /data/nucleus:/data/nucleus:ro \
  -e "DEVICE_ID=$DEVICE_SERIAL" \
  -e "TENANT_ID=559e8400-e29b-41d4-a716-446655440000" \
  -e "AGENT_SECRET=2hRL/Js4yUi/Gm/8VFyhwhdkXFQ+Jsr5lXSaAhXFVk3Qr3udXTZXHDdaG4NdKw5" \
  -e "CONTROL_PLANE_URL=${CONTROL_PLANE}?token=26902cd6-b72b-496e-9326-59517775a95b" \
  -e "MBUSD_BINARY_PATH=/usr/bin/mbusd" \
  "$IMAGE_NAME"

echo "  -> Container created"

# Wait and show logs
echo ""
echo "Waiting 8s for startup..."
sleep 8

echo ""
echo "=== Container Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep "$CONTAINER_NAME"

echo ""
echo "=== Recent Logs ==="
docker logs --tail 15 "$CONTAINER_NAME"

echo ""
echo "=== Done! Agent v0.18.0 reinstalled ==="
