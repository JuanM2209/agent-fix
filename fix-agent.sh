#!/bin/bash
# Nucleus Agent Fix v2 — auto-detects config path
# Usage: curl -sL https://raw.githubusercontent.com/JuanM2209/agent-fix/master/fix-agent.sh | bash

set -e

CONTAINER="remote-s"
CONFIG_URL="https://raw.githubusercontent.com/JuanM2209/agent-fix/master/agent.toml"
TMP_CONFIG="/tmp/agent.toml"

echo "=== Nucleus Agent Fix v2 ==="
echo ""

# 0. Discover where the config lives
echo "[0/5] Discovering config location..."
echo "  Container CMD/args:"
docker inspect "$CONTAINER" --format '{{json .Config.Cmd}}' 2>/dev/null || true
echo ""
echo "  Container entrypoint:"
docker inspect "$CONTAINER" --format '{{json .Config.Entrypoint}}' 2>/dev/null || true
echo ""
echo "  Environment vars:"
docker inspect "$CONTAINER" --format '{{json .Config.Env}}' 2>/dev/null || true
echo ""
echo "  Mounts:"
docker inspect "$CONTAINER" --format '{{json .Mounts}}' 2>/dev/null || true
echo ""

# Find agent.toml inside the container
echo "  Searching for agent.toml inside container..."
CONFIG_PATH=$(docker exec "$CONTAINER" find / -name "agent.toml" -type f 2>/dev/null | head -1)

if [ -z "$CONFIG_PATH" ]; then
  echo "  -> No agent.toml found. Checking /data/ ..."
  CONFIG_PATH="/data/agent.toml"
fi
echo "  -> Config path: $CONFIG_PATH"

# 1. Download correct config
echo ""
echo "[1/5] Downloading agent config..."
curl -sL "$CONFIG_URL" -o "$TMP_CONFIG"
echo "  -> Downloaded to $TMP_CONFIG"

# 2. Show current config
echo ""
echo "[2/5] Current config:"
docker exec "$CONTAINER" cat "$CONFIG_PATH" 2>/dev/null || echo "  (no existing config at $CONFIG_PATH)"

# 3. Ensure parent directory exists and copy config
echo ""
echo "[3/5] Applying new config to $CONFIG_PATH..."
PARENT_DIR=$(dirname "$CONFIG_PATH")
docker exec "$CONTAINER" mkdir -p "$PARENT_DIR" 2>/dev/null || true
docker cp "$TMP_CONFIG" "$CONTAINER":"$CONFIG_PATH"
echo "  -> Config copied"

# 4. Verify
echo ""
echo "[4/5] Verifying new config:"
docker exec "$CONTAINER" cat "$CONFIG_PATH"

# 5. Restart
echo ""
echo "[5/5] Restarting container..."
docker restart "$CONTAINER"
sleep 5

echo ""
echo "=== Recent logs ==="
docker logs --tail 20 "$CONTAINER"

echo ""
echo "=== Done! Device should be ONLINE in the portal ==="
rm -f "$TMP_CONFIG"
