#!/bin/bash
clear

if [[ ! -f "$HOME/.bash_profile" ]]; then
    touch "$HOME/.bash_profile"
fi

if [ -f "$HOME/.bash_profile" ]; then
    source $HOME/.bash_profile
fi

echo "===========EvmoS Protocol Install Easy======= " && sleep 1

read -p "Do you want run node OG Protocol ? (y/n): " choice

if [ "$choice" == "y" ]; then

sudo apt update && sudo apt upgrade -y
sudo apt install make curl git wget htop tmux build-essential jq make lz4 gcc unzip -y

#Install GO
ver="1.22.2"
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version


sudo apt install unzip -y
git clone -b v0.1.0 https://github.com/0glabs/0g-chain.git
./0g-chain/networks/testnet/install.sh
source .profile


0gchaind config keyring-backend test
0gchaind config chain-id zgtendermint_16600-1
0gchaind config node tcp://localhost:14257
0gchaind init NodeName --chain-id zgtendermint_16600-1


sed -i \
  -e 's|^chain-id *=.*|chain-id = "zgtendermint_16600-1"|' \
  -e 's|^keyring-backend *=.*|keyring-backend = "test"|' \
  -e 's|^node *=.*|node = "tcp://localhost:14257"|' \
  $HOME/.0gchain/config/client.toml


### downlaod genesis file
wget -P $HOME/.0gchain/config https://github.com/0glabs/0g-chain/releases/download/v0.1.0/genesis.json

#PEERS="da1f4985ce3df05fd085460485adefa93592a54c@172.232.33.25:26656" && \
SEEDS="c4d619f6088cb0b24b4ab43a0510bf9251ab5d7f@54.241.167.190:26656,44d11d4ba92a01b520923f51632d2450984d5886@54.176.175.48:26656,f2693dd86766b5bf8fd6ab87e2e970d564d20aff@54.193.250.204:26656,f878d40c538c8c23653a5b70f615f8dccec6fb9f@54.215.187.94:26656"
PEERS="6cdd50ed6e958269c259ffc4db17509e15e381bb@185.209.223.10:16656,3a8a28c734a4d32052065d9f6006c14dfa7a4e4e@37.27.59.176:18456,a4055b828e59832c7a06d61fc51347755a160d0b@157.90.33.62:21656,cd529839591e13f5ed69e9a029c5d7d96de170fe@46.4.55.46:34656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.0gchain/config/config.toml

##sed -i -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.0gchain/config/config.toml
OG_PORT=142

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${OG_PORT}17%g;
s%:8080%:${OG_PORT}80%g;
s%:9090%:${OG_PORT}90%g;
s%:9091%:${OG_PORT}91%g;
s%:8545%:${OG_PORT}45%g;
s%:8546%:${OG_PORT}46%g;
s%:6065%:${OG_PORT}65%g" $HOME/.0gchain/config/app.toml
# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${OG_PORT}58%g;
s%:26657%:${OG_PORT}57%g;
s%:6060%:${OG_PORT}60%g;
s%:26656%:${OG_PORT}56%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${OG_PORT}56\"%;
s%:26660%:${OG_PORT}60%g" $HOME/.0gchain/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.0gchain/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.0gchain/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.0gchain/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.005ua0gi"|g' $HOME/.0gchain/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.0gchain/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.0gchain/config/config.toml


sudo tee /etc/systemd/system/0gchaind.service > /dev/null <<EOF
[Unit]
Description=0gchaind Protocol
After=network-online.target
[Service]
User=root
ExecStart=$(which 0gchaind) start --home $HOME/.0gchain
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

cd $HOME

sudo systemctl daemon-reload
sudo systemctl enable 0gchaind
sudo systemctl restart 0gchaind && sudo journalctl -u 0gchaind -f --no-hostname -o cat


echo "===================Install Success==================="

else

echo "Not installed"

fi
