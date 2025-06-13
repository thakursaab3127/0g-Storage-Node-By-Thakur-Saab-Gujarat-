#!/bin/bash

CONFIG_PATH="$HOME/0g-storage-node/run/config.toml"

if [ ! -f "$CONFIG_PATH" ]; then
  echo "❌ config.toml not found at $CONFIG_PATH"
  exit 1
fi

# Ask for new RPC URL
read -rp "Enter the new RPC URL: " NEW_RPC

# Update the RPC line in config.toml
sed -i "s|^blockchain_rpc_endpoint *= *\".*\"|blockchain_rpc_endpoint = \"$NEW_RPC\"|" "$CONFIG_PATH"

echo "✅ RPC updated to: $NEW_RPC"

# Restart the node service
echo "🔄 Restarting the zgs node service..."
sudo systemctl restart zgs

echo "✅ Node restarted. Check status with: sudo systemctl status zgs"
