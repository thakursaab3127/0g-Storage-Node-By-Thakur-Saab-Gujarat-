#!/bin/bash

CONFIG_PATH="$HOME/0g-storage-node/run/config.toml"

if [ ! -f "$CONFIG_PATH" ]; then
  echo "❌ config.toml not found at $CONFIG_PATH"
  exit 1
fi

# Prompt user for the new RPC endpoint
read -rp "Enter the new RPC URL: " NEW_RPC

# Validate that it's not empty
if [ -z "$NEW_RPC" ]; then
  echo "❌ RPC URL cannot be empty."
  exit 1
fi

# Update the blockchain_rpc_endpoint line
sed -i "s|^blockchain_rpc_endpoint *= *\".*\"|blockchain_rpc_endpoint = \"$NEW_RPC\"|" "$CONFIG_PATH"

echo "✅ Updated RPC in config.toml to: $NEW_RPC"

# Reload systemd daemon and restart the service
echo "🔄 Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "🔁 Restarting zgs service..."
sudo systemctl restart zgs

echo "✅ Node restarted successfully."
echo "📍 Check status with: sudo systemctl status zgs"
