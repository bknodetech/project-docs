#!/bin/bash

render_dashboard() {
    clear
    printf "
    ██████  ██   ██ ███    ██  ██████  ██████  ███████ 
    ██   ██ ██  ██  ████   ██ ██    ██ ██   ██ ██      
    ██████  █████   ██ ██  ██ ██    ██ ██   ██ █████   
    ██   ██ ██  ██  ██  ██ ██ ██    ██ ██   ██ ██      
    ██████  ██   ██ ██   ████  ██████  ██████  ███████ 

    Website: bknode.tech        X: @bknodetech     Github: bknodetech

WELCOME TO STORY TESTNET DASHBOARD BY BKNODE!

Please choose your action:
1. Install node
2. Install snapshot
3. Get logs
4. Get sync status
5. Get version
6. Client upgrade
7. Quit

Please enter your choice: "
}

install_node() {
    read -p "Enter your moniker: " moniker

    # Define versions as variables
    local go_version="1.22.4"
    local story_geth_version="0.9.3-b224fdf"
    local story_version="0.9.13-b4c7db1"
    local install_dir="$HOME/.story/story"

    # Install required packages
    sudo apt update && sudo apt upgrade -y && sudo apt install -y \
        curl git jq build-essential gcc unzip wget lz4

    # Install Go
    wget -q "https://golang.org/dl/go$go_version.linux-amd64.tar.gz" -O /tmp/go.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
    export PATH=$PATH:/usr/local/go/bin:~/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin:~/go/bin' >>~/.bash_profile
    source ~/.bash_profile

    # Install Story Geth binary
    wget -q "https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public/geth-linux-amd64-$story_geth_version.tar.gz" -O /tmp/geth.tar.gz
    tar -xzf /tmp/geth.tar.gz -C /tmp
    mkdir -p ~/go/bin
    sudo mv /tmp/geth-linux-amd64-$story_geth_version/geth ~/go/bin/story-geth
    rm -rf /tmp/geth*

    # Install Story binary using Cosmovisor
    wget -q "https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-$story_version.tar.gz" -O /tmp/story.tar.gz
    tar -xzf /tmp/story.tar.gz -C /tmp
    mkdir -p $install_dir/cosmovisor/genesis/bin
    sudo mv /tmp/story-linux-amd64-$story_version/story $install_dir/cosmovisor/genesis/bin/story
    rm -rf /tmp/story*

    # Install the latest version of Cosmovisor
    go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

    # Setup Cosmovisor environment variables
    mkdir -p $install_dir/cosmovisor
    {
        echo 'export DAEMON_NAME=story'
        echo "export DAEMON_HOME=$install_dir"
        echo "export PATH=$HOME/go/bin:$install_dir/cosmovisor/current/bin:$PATH"
    } >>~/.bash_profile
    source ~/.bash_profile

    # Initialize The Iliad Network Node
    $install_dir/cosmovisor/genesis/bin/story init --moniker "$moniker" --network iliad

    # Update Peers
    local PEERS
    PEERS=$(curl -sS https://story-testnet.rpc.bknode.tech/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}' | paste -sd, -)
    printf "Updating peers...\n"
    sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" "$install_dir/config/config.toml"

    # Create and Configure systemd Services for Story-Geth and Cosmovisor
    sudo tee /etc/systemd/system/story-geth.service >/dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target
[Service]
User=$USER
ExecStart=$HOME/go/bin/story-geth --iliad --syncmode full
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

    sudo tee /etc/systemd/system/story.service >/dev/null <<EOF
[Unit]
Description=Cosmovisor service for Story binary
After=network.target
[Service]
User=$USER
ExecStart=$HOME/go/bin/cosmovisor run run
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
Environment="DAEMON_NAME=story"
Environment="DAEMON_HOME=$install_dir"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_DATA_BACKUP_DIR=$install_dir/data"
Environment="UNSAFE_SKIP_BACKUP=true"
[Install]
WantedBy=multi-user.target
EOF

    # Reload systemctl, start services
    sudo systemctl daemon-reload
    sudo systemctl enable story story-geth
    sudo systemctl start story story-geth

    printf "\nStory Node installed successfully!\n"

    while true; do
        printf "\nWhat would you like to do next?\n1. Back to dashboard menu\n2. Quit\n"
        read -p "Enter your choice: " answer
        case $answer in
        1) return ;;
        2)
            printf "Goodbye!\n"
            exit 0
            ;;
        *) printf "Invalid!\n" ;;
        esac
    done
}

install_snapshot() {
    latest_url="http://ws2.bknode.tech/snapshots/story/latest.txt"
    echo $latest_url

    wget -q -O - "$latest_url" | while read -r line; do
        echo $line
        if [[ "$line" == geth_* ]]; then
            geth_snapshot_url="http://ws2.bknode.tech/snapshots/story/$line"
        fi

        if [[ "$line" == story_* ]]; then
            story_snapshot_url="http://ws2.bknode.tech/snapshots/story/$line"
        fi
    done

    echo "Geth Snapshot URL: $geth_snapshot_url"
    echo "Story Snapshot URL: $story_snapshot_url"
    read -p "Enter your moniker: " moniker
}

get_logs() {
    printf "\nPlease choose the logs to check:\n1. Check Story Logs\n2. Check Story-Geth Logs\n3. Quit\nPlease enter your choice: "
    read -p "Please enter your choice: " answer

    if [[ "$answer" =~ ^[1-3]$ ]]; then
        case $answer in
        1) log_name="Story" ;;
        2) log_name="Story-Geth" ;;
        3)
            printf "Exiting log check.\n"
            return
            ;;
        esac
        printf "Checking %s logs... Press Ctrl+C to exit\n" "$log_name"
        sudo journalctl -u ${log_name,,} -f -o cat
    else
        printf "Invalid!\n"
    fi
}

get_sync_status() {
    local status_url="https://story-testnet.rpc.bknode.tech/status"
    local local_url="localhost:26657/status"

    while true; do
        # Get local and network heights
        local local_height network_height blocks_left
        local_height=$(curl -s "$local_url" | jq -r '.result.sync_info.latest_block_height')
        network_height=$(curl -s "$status_url" | jq -r '.result.sync_info.latest_block_height')

        # Calculate blocks left to sync
        blocks_left=$((network_height - local_height))

        # Print status with improved readability
        printf "\e[32mYour node height:\e[0m \e[34m%s\e[0m | \e[33mNetwork height:\e[0m \e[36m%s\e[0m | \e[37mBlocks left:\e[0m \e[31m%s\e[0m\n" \
            "$local_height" "$network_height" "$blocks_left"

        sleep 3
    done
}

# Schedule a Story Client Upgrade
upgrade_client() {
    printf "\nSchedule a Story Client Upgrade\n"
    read -p "Enter the Client Upgrade link: " upgrade_link
    read -p "Enter the Client version: " client_version
    read -p "Enter the Upgrade Height: " upgrade_height

    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    printf "Downloading and extracting the Client...\n"
    curl -L "$upgrade_link" | tar -xz

    client_executable=$(find . -type f -executable | head -n 1)
    if [ -z "$client_executable" ]; then
        printf "Error: No executable file found in the downloaded archive.\n"
        rm -rf "$temp_dir"
        return
    fi

    client_path=$(readlink -f "$client_executable")
    printf "Scheduling the upgrade...\n"
    cosmovisor add-upgrade "$client_version" "$client_path" --force --upgrade-height "$upgrade_height"

    rm -rf "$temp_dir"
    printf "Upgrade scheduled successfully!\n"

    while true; do
        printf "\nWhat would you like to do next?\n1. Back to dashboard menu\n2. Quit\n"
        read -p "Enter your choice: " answer
        case $answer in
        1) return ;;
        2)
            printf "Goodbye!\n"
            exit 0
            ;;
        *) printf "Invalid!\n" ;;
        esac
    done
}

get_version() {
    printf "Please choose which version to check:\n1. Story Version\n2. Story-Geth Version\n3. Back to main menu\nPlease enter your choice: "
    read -r answer

    case $answer in
    1) cosmovisor run version ;;
    2) story-geth version ;;
    3) return ;;
    *) printf "Invalid!\n" ;;
    esac

    read -p "Press Enter to continue..."
}

# Main script loop
while true; do
    render_dashboard
    read answer
    case $answer in
    1) install_node ;;
    2) install_snapshot ;;
    3) get_logs ;;
    4) get_sync_status ;;
    5) get_version ;;
    6) upgrade_client ;;
    7) exit 0 ;;
    *) printf "Invalid!\n" ;;
    esac
done
