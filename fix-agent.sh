#!/bin/bash
# Nucleus Agent Fix — updates token config and restarts container
# Usage: curl -sL https://raw.githubusercontent.com/JML-Nucleus/agent-fix/main/fix-agent.sh | bash

set -e

CONTAINER="remote-s"
CONFIG_URL="https://raw.githubusercontent.com/JML-Nucleus/agent-fix/main/agent.toml"
TMP_CONFIG="/tmp/agent.toml"

echo "=== Nucleus Agent Fix ==="
echo ""

# 1. Download correct config
echo "[1/4] Downloading agent config..."
curl -sL "$CONFIG_URL" -o "$TMP_CONFIG"
echo "  -> Downloaded to $TMP_CONFIG"

# 2. Show current config for reference
echo ""
echo "[2/4] Current config in container:"
docker exec "$CONTAINER" cat /etc/nucleus/agent.toml 2>/dev/null || echo "  (could not read current config)"

# 3. Copy new config into container
echo ""
echo "[3/4] Applying new config..."
docker cp "$TMP_CONFIG" "$CONTAINER":/etc/nucleus/agent.toml
echo "  -> Config copied to $CONTAINER:/etc/nucleus/agent.toml"

# 4. Restart container
echo ""
echo "[4/4] Restarting container..."
docker restart "$CONTAINER"
echo "  -> Container restarted"

# 5. Wait and show logs
echo ""
echo "=== Waiting 5s for agent to connect... ==="
sleep 5
echo ""
echo "=== Recent logs ==="
docker logs --tail 20 "$CONTAINER"

echo ""
echo "=== Done! Check the portal — device should be ONLINE ==="

# Cleanup
rm -f "$TMP_CONFIG"
