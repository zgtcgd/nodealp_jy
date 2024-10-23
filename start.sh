#!/bin/bash

# Define Environment Variables
export V_PORT=${V_PORT:-'8080'}
export CFPORT=${CFPORT:-'443'} # https 443 2053 2083 2087 2096 8443  # http 80 8080 8880 2052 2082 2086 2095
export UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
export VMESS_WSPATH=${VMESS_WSPATH:-'startvm'}
export VLESS_WSPATH=${VLESS_WSPATH:-'startvl'}
export CF_IP=${CF_IP:-'ip.sb'}
export MY_DOMAIN="$MY_DOMAIN"
export FILE_PATH=${FILE_PATH:-'/tmp'}

export openserver=${openserver:-'1'}
export openkeepalive=${openkeepalive:-'0'}

export SUB_URL="$SUB_URL"
export SUB_NAME="$SUB_NAME"

export NEZHA_SERVER="$NEZHA_SERVER"
export NEZHA_KEY="$NEZHA_KEY"
export NEZHA_PORT=${NEZHA_PORT:-'443'}

export ARGO_DOMAIN="$ARGO_DOMAIN"
export ARGO_AUTH="$ARGO_AUTH"

hint() { echo -e "\033[33m\033[01m$*\033[0m"; }   # yellow

if [ ! -d "$FILE_PATH" ]; then
  mkdir -p "$FILE_PATH"
fi

cleanup_files() {
  rm -rf ${FILE_PATH}/*.log ${FILE_PATH}/*.json ${FILE_PATH}/*.txt ${FILE_PATH}/*.sh ${FILE_PATH}/tunnel.*
}

# Download Dependency Files
set_download_url() {
  local program_name="$1"
  local default_url="$2"
  local x64_url="$3"

  if [ "$(uname -m)" = "x86_64" ] || [ "$(uname -m)" = "amd64" ] || [ "$(uname -m)" = "x64" ]; then
    download_url="$x64_url"
  else
    download_url="$default_url"
  fi
}

download_program() {
  local program_name="$1"
  local default_url="$2"
  local x64_url="$3"

  set_download_url "$program_name" "$default_url" "$x64_url"

  if [ ! -f "$program_name" ]; then
    if [ -n "$download_url" ]; then
      echo "Downloading $program_name..." > /dev/null
      # wget -q -O "$program_name" "$download_url"
      curl -sSL "$download_url" -o "$program_name"
      echo "Downloaded $program_name" > /dev/null
    else
      echo "Skipping download for $program_name" > /dev/null
    fi
  else
    echo "$program_name already exists, skipping download" > /dev/null
  fi
}

initialize_downloads() {
  if [ -n "${NEZHA_SERVER}" ] && [ -n "${NEZHA_KEY}" ]; then
    download_program "${FILE_PATH}/agent" "https://github.com/kahunama/myfile/releases/download/main/nezha-agent_arm" "https://github.com/kahunama/myfile/releases/download/main/nezha-agent"
    chmod +x ${FILE_PATH}/agent
    sleep 3
  fi

  download_program "${FILE_PATH}/data" "https://github.com/mytcgd/myfiles/releases/download/main/xray_arm" "https://github.com/mytcgd/myfiles/releases/download/main/xray"
  chmod +x ${FILE_PATH}/data
  sleep 3

  if [ ${openserver} -eq 1 ]; then
    download_program "${FILE_PATH}/server" "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
    chmod +x ${FILE_PATH}/server
    sleep 3
  fi

  if [ -n "${SUB_URL}" ]; then
    download_program "${FILE_PATH}/up.sh" "https://raw.githubusercontent.com/mytcgd/myfiles/main/my/x/up_s.sh" "https://raw.githubusercontent.com/mytcgd/myfiles/main/my/x/up_s.sh"
    chmod +x ${FILE_PATH}/up.sh
    sleep 3
  fi
}

# check_chatgpt
check_chatgpt() {
  local SUPPORT_COUNTRY=(AD AE AF AG AL AM AO AR AT AU AZ BA BB BD BE BF BG BH BI BJ BN BO BR BS BT BW BZ CA CD CF CG CH CI CL CM CO CR CV CY CZ DE DJ DK DM DO DZ EC EE EG ER ES ET FI FJ FM FR GA GB GD GE GH GM GN GQ GR GT GW GY HN HR HT HU ID IE IL IN IQ IS IT JM JO JP KE KG KH KI KM KN KR KW KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MG MH MK ML MM MN MR MT MU MV MW MX MY MZ NA NE NG NI NL NO NP NR NZ OM PA PE PG PH PK PL PS PT PW PY QA RO RS RW SA SB SC SD SE SG SI SK SL SM SN SO SR SS ST SV SZ TD TG TH TJ TL TM TN TO TR TT TV TW TZ UA UG US UY UZ VA VC VN VU WS YE ZA ZM ZW)
  [[ "${SUPPORT_COUNTRY[@]}" =~ $(curl -s -k -m 2 https://chat.openai.com/cdn-cgi/trace | awk -F '=' '/loc/{print $2}') ]] && echo 'unlock' || echo 'ban'
  # [[ "${SUPPORT_COUNTRY[@]}" =~ $(wget --no-check-certificate -qO- --tries=3 --timeout=2 https://chat.openai.com/cdn-cgi/trace | awk -F '=' '/loc/{print $2}') ]] && echo 'unlock' || echo 'ban'
}

# my_config
my_config() {
  # Check whether chatGPT is unlocked
  if [ "$(check_chatgpt)" = 'unlock' ]; then
    CHAT_GPT_OUT="direct"
  else
    CHAT_GPT_OUT="WARP"
  fi

  if [[ ! "$SERVER_IP" =~ : ]]; then
    WARP_ENDPOINT=162.159.193.10
  else
    WARP_ENDPOINT=2606:4700:d0::a29f:c101
  fi

  generate_config() {
  cat > ${FILE_PATH}/out.json << EOF
{
    "log": {
        "access": "/dev/null",
        "error": "/dev/null",
        "loglevel": "none"
    },
    "dns": {
        "servers": [
            "https+local://8.8.8.8/dns-query"
        ]
    },
    "inbounds": [
        {
            "port": $V_PORT,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${UUID}",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "path": "/${VLESS_WSPATH}",
                        "dest": 3002
                    },
                    {
                        "path": "/${VMESS_WSPATH}",
                        "dest": 3003
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp"
            }
        },
        {
            "port": 3002,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${UUID}",
                        "level": 0
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "/${VLESS_WSPATH}"
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly": false
            }
        },
        {
            "port": 3003,
            "listen": "127.0.0.1",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "${UUID}",
                        "alterId": 0
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/${VMESS_WSPATH}"
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly": false
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "tag": "WARP",
            "protocol": "wireguard",
            "settings": {
                "secretKey": "YFYOAdbw1bKTHlNNi+aEjBM3BO7unuFC5rOkMRAz9XY=",
                "address": [
                    "172.16.0.2/32",
                    "2606:4700:110:8a36:df92:102a:9602:fa18/128"
                ],
                "peers": [
                    {
                        "publicKey": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
                        "allowedIPs": [
                            "0.0.0.0/0",
                            "::/0"
                        ],
                        "endpoint": "${WARP_ENDPOINTCHAT_GPT_OUT}:2408"
                    }
                ],
                "reserved": [78, 135, 76],
                "mtu": 1280
            }
        }
    ],
    "routing": {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "type": "field",
                "domain": [
                    "domain:openai.com",
                    "domain:ai.com",
                    "domain:chat.openai.com",
                    "domain:chatgpt.com"
                ],
                "outboundTag": "${CHAT_GPT_OUT}"
            }
        ]
    }
}
EOF
  }

  argo_type() {
    if [ -e "${FILE_PATH}/server" ] && [ -z "$ARGO_AUTH" ] && [ -z "$ARGO_DOMAIN" ]; then
      echo "ARGO_AUTH or ARGO_DOMAIN is empty, use Quick Tunnels" > /dev/null
      return
    fi

    if [ -e "${FILE_PATH}/server" ] && [ -n "$(echo "$ARGO_AUTH" | grep TunnelSecret)" ]; then
      echo $ARGO_AUTH > ${FILE_PATH}/tunnel.json
      cat > ${FILE_PATH}/tunnel.yml << EOF
tunnel=$(echo "$ARGO_AUTH" | cut -d\" -f12)
credentials-file: ${FILE_PATH}/tunnel.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost: $V_PORT
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
    else
      echo "ARGO_AUTH Mismatch TunnelSecret" > /dev/null
    fi
  }

  args() {
    if [ ${openserver} -eq 1 ] && [ -e "${FILE_PATH}/server" ]; then
      if [ -n "$(echo "$ARGO_AUTH" | grep '^[A-Z0-9a-z=]\{120,250\}$')" ]; then
        args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token ${ARGO_AUTH}"
      elif [ -n "$(echo "$ARGO_AUTH" | grep TunnelSecret)" ]; then
        args="tunnel --edge-ip-version auto --config ${FILE_PATH}/tunnel.yml run"
      else
        args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile ${FILE_PATH}/boot.log --loglevel info --url http://localhost:${V_PORT}"
      fi
    fi
  }

  generate_config
  argo_type
  args
}

# run
run_server() {
  if [ -e ${FILE_PATH}/$server_randomness ]; then
    ${FILE_PATH}/$server_randomness $args > /dev/null 2>&1 &
  fi
}

run_data() {
  if [ -e ${FILE_PATH}/$data_randomness ]; then
    ${FILE_PATH}/$data_randomness run -c ${FILE_PATH}/out.json >/dev/null 2>&1 &
  fi
}

run_agent() {
  if [ -n "${NEZHA_SERVER}" ] && [ -n "${NEZHA_KEY}" ] && [ -e ${FILE_PATH}/$nez_randomness ]; then
    tlsPorts=("443" "8443" "2096" "2087" "2083" "2053")
    if [[ " ${tlsPorts[@]} " =~ " ${NEZHA_PORT} " ]]; then
      NEZHA_TLS="--tls"
    else
      NEZHA_TLS=""
    fi
    ${FILE_PATH}/$nez_randomness -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_TLS} > /dev/null 2>&1 &
  fi
}

keep_alive() {
  if [[ ! $(pidof $server_randomness) ]]; then
    run_server
    sleep 5
    get_ip_country_code && check_hostname_change && build_urls
    hint "$server_randomness runs again !"
  fi

  sleep 5

  if [[ ! $(pidof $data_randomness) ]]; then
    run_data
    hint "$data_randomness runs again !"
  fi

  sleep 5

  if [[ ! $(pidof $nez_randomness) ]]; then
    run_agent
    hint "$nez_randomness runs again !"
  fi
}

run_processes() {
  server_randomness=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 4)
  data_randomness=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 5)
  nez_randomness=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)

  [ -e "${FILE_PATH}/server" ] && mv ${FILE_PATH}/server ${FILE_PATH}/${server_randomness} && sleep 1
  run_server

  sleep 5

  [ -e "${FILE_PATH}/data" ] && mv ${FILE_PATH}/data ${FILE_PATH}/${data_randomness} && sleep 1
  run_data

  [ -e "${FILE_PATH}/agent" ] && mv ${FILE_PATH}/agent ${FILE_PATH}/${nez_randomness} && sleep 1
  run_agent

  check_hostname_change && build_urls && sleep 3

  if [ -n "$SUB_URL" ] && [ -e "${FILE_PATH}/up.sh" ]; then
    bash ${FILE_PATH}/up.sh > /dev/null 2>&1 &
  fi

  case "$openkeepalive" in
    "1" )
      while true
      do
      keep_alive
      sleep 50
      done
      ;;
  esac
}

# get IP and country
get_ip_country_code() {
  export SERVER_IP=$(curl -s https://speed.cloudflare.com/meta | tr ',' '\n' | grep -E '"clientIp"\s*:\s*"' | sed 's/.*"clientIp"\s*:\s*"\([^"]*\)".*/\1/')
  # export SERVER_IP=$(curl -s https://ipinfo.io/ip)
  # echo "${SERVER_IP}"

  export country_abbreviation=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g')   # Display ISP and country abbreviation
  # export country_abbreviation=$(curl -s https://speed.cloudflare.com/meta | tr ',' '\n' | grep -E '"country"\s*:\s*"' | sed 's/.*"country"\s*:\s*"\([^"]*\)".*/\1/')   # Display country abbreviation
  # echo "${country_abbreviation}"
}

# check_hostname
check_hostname_change() {
  if [ -z "$ARGO_AUTH" ] && [ -z "$ARGO_DOMAIN" ]; then
    [ -s ${FILE_PATH}/boot.log ] && export ARGO_DOMAIN=$(cat ${FILE_PATH}/boot.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
    # [ -s ${FILE_PATH}/boot.log ] && export ARGO_DOMAIN=$(cat ${FILE_PATH}/boot.log | grep -o "https://.*trycloudflare.com" | tail -n 1 | sed 's/https:\/\///')
  fi
}

# build_urls
build_urls() {
  # openserver is not 1
  if [ ${openserver} -ne 1 ]; then
    echo "Please set up the cf reverse proxy domain name!"
    export ARGO_DOMAIN="$MY_DOMAIN"
  fi

  export VMESS="{ \"v\": \"2\", \"ps\": \"vmess-${country_abbreviation}-${SUB_NAME}\", \"add\": \"${CF_IP}\", \"port\": \"${CFPORT}\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${ARGO_DOMAIN}\", \"path\": \"/${VMESS_WSPATH}?ed=2048\", \"tls\": \"tls\", \"sni\": \"${ARGO_DOMAIN}\", \"alpn\": \"\" }"

  cat > ${FILE_PATH}/tmp.txt << ABC
***************************************************

      IP : ${server_ip}     Country： ${country_abbreviation}

***************************************************

vmess://$(echo "$VMESS" | base64 | tr -d '\n')

vless://${UUID}@${CF_IP}:${CFPORT}?host=${ARGO_DOMAIN}&path=%2F${VLESS_WSPATH}%3Fed%3D2048&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#vless-${country_abbreviation}-${SUB_NAME}

***************************************************
ABC

  cat > ${FILE_PATH}/encode.txt << DEF
vmess://$(echo "$VMESS" | base64 | tr -d '\n')
vless://${UUID}@${CF_IP}:${CFPORT}?host=${ARGO_DOMAIN}&path=%2F${VLESS_WSPATH}%3Fed%3D2048&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#vless-${country_abbreviation}-${SUB_NAME}
DEF

  base64 ${FILE_PATH}/encode.txt | tr -d '\n' > ${FILE_PATH}/log.txt
  rm ${FILE_PATH}/encode.txt
}

# main
main() {
  echo "Server is running on port : ${SERVER_PORT}"
  cleanup_files
  initialize_downloads
  get_ip_country_code
  my_config
  run_processes
}
main
