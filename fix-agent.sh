#!/bin/bash
# Nucleus Agent Fix v4 — recreate container with token in URL
# Usage: curl -sL https://raw.githubusercontent.com/JuanM2209/agent-fix/master/fix-agent.sh | bash

CONTAINER="remote-s"
DEVICE_UUID="26902cd6-b72b-496e-9326-59517775a95b"

echo "=== Nucleus Agent Fix v4 ==="
echo ""

# 1. Get current container config
echo "[1/5] Reading current container config..."
IMAGE=$(docker inspect "$CONTAINER" --format '{{.Config.Image}}')
echo "  Image: $IMAGE"

# Get all current env vars
echo "  Current env vars:"
docker exec "$CONTAINER" env | grep -v "^PATH=" | grep -v "^HOME="

# Get network mode
NETWORK=$(docker inspect "$CONTAINER" --format '{{.HostConfig.NetworkMode}}')
echo "  Network: $NETWORK"

# Get restart policy
RESTART=$(docker inspect "$CONTAINER" --format '{{.HostConfig.RestartPolicy.Name}}')
echo "  Restart: $RESTART"

echo ""
echo "[2/5] Stopping old container..."
docker stop "$CONTAINER"
docker rename "$CONTAINER" "${CONTAINER}-backup"
echo "  -> Old container renamed to ${CONTAINER}-backup"

echo ""
echo "[3/5] Creating new container with token in URL..."
docker run -d \
  --name "$CONTAINER" \
  --hostname N-1065 \
  --network "$NETWORK" \
  --restart "${RESTART:-unless-stopped}" \
  -e "DEVICE_ID=N-1065" \
  -e "TENANT_ID=559e8400-e29b-41d4-a716-446655440000" \
  -e "AGENT_SECRET=2hRL/Js4yUi/Gm/8VFyhwhdkXFQ+Jsr5lXSaAhXFVk3Qr3udXTZXHDdaG4NdKw5" \
  -e "CONTROL_PLANE_URL=wss://api.datadesng.com/ws/agent?token=${DEVICE_UUID}" \
  "$IMAGE"

echo "  -> New container created"

echo ""
echo "[4/5] Verifying new config..."
echo "  New CONTROL_PLANE_URL:"
docker exec "$CONTAINER" printenv CONTROL_PLANE_URL

echo ""
echo "[5/5] Waiting 5s for connection..."
sleep 5
echo ""
echo "=== Recent logs ==="
docker logs --tail 20 "$CONTAINER"

echo ""
echo "=== Done! Check portal — device should be ONLINE ==="
echo ""
echo "If something went wrong, restore with:"
echo "  docker stop $CONTAINER && docker rm $CONTAINER"
echo "  docker rename ${CONTAINER}-backup $CONTAINER"
echo "  docker start $CONTAINER"
