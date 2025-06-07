#!/bin/bash

set -e

# === Colors ===
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# BANNER
echo -e "${GREEN}"
cat << 'EOF'
 ______              _         _                                             
|  ___ \            | |       | |                   _                        
| |   | |  ___    _ | |  ____ | | _   _   _  ____  | |_   ____   ____  _____ 
| |   | | / _ \  / || | / _  )| || \ | | | ||  _ \ |  _) / _  ) / ___)(___  )
| |   | || |_| |( (_| |( (/ / | | | || |_| || | | || |__( (/ / | |     / __/ 
|_|   |_| \___/  \____| \____)|_| |_| \____||_| |_| \___)\____)|_|    (_____)
EOF
echo -e "${NC}"

# === Prompt for Wallet Private Key ===
read -rp "Enter your Wallet PRIVATE KEY (64 hex characters, without 0x): " WALLET_KEY
WALLET_KEY="${WALLET_KEY#0x}" # remove 0x prefix if present

# === Prompt for Custom RPC URL ===
read -rp "Do you want to use a custom RPC URL? (y/n): " USE_CUSTOM_RPC
if [[ "$USE_CUSTOM_RPC" =~ ^[Yy]$ ]]; then
  read -rp "Enter the custom RPC URL: " RPC_URL
else
  RPC_URL="https://evmrpc-testnet.0g.ai"
fi

# === Install dependencies ===
echo -e "${YELLOW}Installing dependencies...${RESET}"
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install -y curl iptables build-essential git wget lz4 jq make cmake gcc nano \
automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev \
tar clang bsdmainutils ncdu unzip screen ufw

# === Install Rust ===
if ! command -v rustc &>/dev/null; then
  echo -e "${YELLOW}Installing Rust...${RESET}"
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source $HOME/.cargo/env
fi

# === Install Go ===
if ! command -v go &>/dev/null; then
  echo -e "${YELLOW}Installing Go...${RESET}"
  wget https://go.dev/dl/go1.24.3.linux-amd64.tar.gz
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf go1.24.3.linux-amd64.tar.gz
  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
  source ~/.bashrc
  rm go1.24.3.linux-amd64.tar.gz
fi

# === Clone and build the storage node ===
echo -e "${YELLOW}Cloning and building the node...${RESET}"
git clone https://github.com/0glabs/0g-storage-node.git
cd 0g-storage-node && git checkout v1.0.0 && git submodule update --init
cargo build --release

# === Create config directory ===
mkdir -p $HOME/0g-storage-node/run

# === Write minimal config.toml ===
echo -e "${YELLOW}Generating minimal config.toml...${RESET}"
cat > $HOME/0g-storage-node/run/config.toml <<EOF
network_boot_nodes = [
  "/ip4/47.251.117.133/udp/1234/p2p/16Uiu2HAmTVDGNhkHD98zDnJxQWu3i1FL1aFYeh9wiQTNu4pDCgps",
  "/ip4/47.76.61.226/udp/1234/p2p/16Uiu2HAm2k6ua2mGgvZ8rTMV8GhpW71aVzkQWy7D37TTDuLCpgmX",
  "/ip4/47.251.79.83/udp/1234/p2p/16Uiu2HAkvJYQABP1MdvfWfUZUzGLx1sBSDZ2AT92EFKcMCCPVawV",
  "/ip4/47.238.87.44/udp/1234/p2p/16Uiu2HAmFGsLoajQdEds6tJqsLX7Dg8bYd2HWR4SbpJUut4QXqCj",
  "/ip4/47.251.78.104/udp/1234/p2p/16Uiu2HAmSe9UWdHrqkn2mKh99b9DwYZZcea6krfidtU3e5tiHiwN",
  "/ip4/47.76.30.235/udp/1234/p2p/16Uiu2HAm5tCqwGtXJemZqBhJ9JoQxdDgkWYavfCziaqaAYkGDSfU"
]

blockchain_rpc_endpoint = "$RPC_URL"
log_contract_address = "0xbD75117F80b4E22698D0Cd7612d92BDb8eaff628"
log_sync_start_block_number = 326165
mine_contract_address = "0x3A0d1d67497Ad770d6f72e7f4B8F0BAbaa2A649C"
reward_contract_address = "0xd3D4D91125D76112AE256327410Dd0414Ee08Cb4"
miner_key = "$WALLET_KEY"
EOF

# === Create systemd service ===
echo -e "${YELLOW}Setting up systemd service...${RESET}"
sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOL
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOL

# === Start node service ===
sudo systemctl daemon-reload
sudo systemctl enable zgs
sudo systemctl start zgs

echo -e "${GREEN}✅ 0G Storage Node setup complete!"
echo -e "Check status with: sudo systemctl status zgs"
echo -e "Check logs with:   tail -f ~/0g-storage-node/run/log/zgs.log.\$(date +%F)"
echo -e "${RESET}"
echo -e "Use 'sudo systemctl status zgs' to check the service status.${RESET}"
