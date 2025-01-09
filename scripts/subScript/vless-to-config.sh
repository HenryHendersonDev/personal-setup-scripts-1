#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Please run with 'sudo'."
  exit 1
fi

# Prompt for user inputs
echo "Please enter your server host:"
read host

echo "Please enter your Port:"
read port

echo "Please enter your UUID:"
read uuid

echo "Please enter your SNI:"
read sni

echo "Please enter your ALPN values (comma-separated, e.g., h2,http/1.1):"
read alpn_input

# Process ALPN input
IFS=',' read -ra ALPN_ARRAY <<<"$alpn_input"

# Generate ALPN JSON array
alpn_json=""
for i in "${ALPN_ARRAY[@]}"; do
  if [ -n "$alpn_json" ]; then
    alpn_json="$alpn_json,"
  fi
  alpn_json="$alpn_json\"$i\""
done

# If ALPN is empty, use default values
if [ -z "$alpn_json" ]; then
  alpn_json="\"h2\",\"http/1.1\""
fi

# Define the config path
configPath="/usr/local/xray/config.json"
dirPath="/usr/local/xray"

# Check if the directory exists
if [ ! -d "$dirPath" ]; then
  echo "Directory $dirPath does not exist. Creating it..."
  mkdir -p "$dirPath"
  chmod 777 "$dirPath"
  echo "Directory $dirPath created and permissions set to 777."
else
  echo "Directory $dirPath already exists."
fi

# Check if the file exists
if [ -f "$configPath" ]; then
  echo "File $configPath exists. Removing it..."
  rm -f "$configPath"
  echo "File $configPath has been removed."
else
  echo "File $configPath does not exist."
fi

# Create the config.json file
cat >$configPath <<EOF
{
  "log": {
    "loglevel": "info"
  },
  "inbounds": [
    {
      "tag": "socks-in",
      "port": 10808,
      "protocol": "socks",
      "settings": {
        "udp": true,
        "auth": "noauth"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "tag": "http-in",
      "port": 10809,
      "protocol": "http",
      "settings": {},
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "$host",
            "port": $port,
            "users": [
              {
                "id": "$uuid",
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "serverName": "$sni",
          "allowInsecure": true,
          "fingerprint": "chrome",
          "alpn": [
            $alpn_json
          ]
        },
        "wsSettings": {
          "path": "/"
        }
      }
    }
  ]
}
EOF

sudo chmod +x $configPath

echo "Config file has been saved to $configPath"
