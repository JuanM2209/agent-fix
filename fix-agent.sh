#!/bin/bash
# Nucleus Agent Fix v3 — inspect + env var approach
# Usage: curl -sL https://raw.githubusercontent.com/JuanM2209/agent-fix/master/fix-agent.sh | bash

CONTAINER="remote-s"

echo "=== Nucleus Agent Fix v3 ==="
echo ""
echo "[1] Inspecting container..."
echo "--- Image ---"
docker inspect "$CONTAINER" --format '{{.Config.Image}}' 2>/dev/null
echo ""
echo "--- CMD ---"
docker inspect "$CONTAINER" --format '{{json .Config.Cmd}}' 2>/dev/null
echo ""
echo "--- Entrypoint ---"
docker inspect "$CONTAINER" --format '{{json .Config.Entrypoint}}' 2>/dev/null
echo ""
echo "--- Env ---"
docker inspect "$CONTAINER" --format '{{json .Config.Env}}' 2>/dev/null
echo ""
echo "--- Mounts ---"
docker inspect "$CONTAINER" --format '{{json .Mounts}}' 2>/dev/null
echo ""
echo "--- Filesystem root ---"
docker exec "$CONTAINER" ls -la / 2>/dev/null
echo ""
echo "--- Find agent.toml ---"
docker exec "$CONTAINER" find / -name "*.toml" 2>/dev/null
echo ""
echo "--- Find config dirs ---"
docker exec "$CONTAINER" ls -la /etc/ 2>/dev/null | head -20
echo ""
docker exec "$CONTAINER" ls -la /data/ 2>/dev/null
echo ""
echo "--- Process list ---"
docker exec "$CONTAINER" ps aux 2>/dev/null || docker top "$CONTAINER" 2>/dev/null
echo ""
echo "=== Copy this output and paste it back ==="
