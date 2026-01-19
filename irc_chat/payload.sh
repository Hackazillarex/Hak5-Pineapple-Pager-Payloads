#!/bin/bash
# Title: IRC Chat
# Author: Hackazillarex
# Description: Chat via IRC
# Version: 1.0

# Web version to chat back via device is https://webchat.oftc.net 
SERVER="irc.oftc.net"
PORT=6667

################################
# Pick nickname
################################
LOG white "Pick IRC nickname..."
NICK=$(TEXT_PICKER "IRC Nickname" "PagerBot")
case $? in
    $DUCKYSCRIPT_CANCELLED|$DUCKYSCRIPT_REJECTED|$DUCKYSCRIPT_ERROR)
        exit 0
        ;;
esac

################################
# Pick channel
################################
LOG white "Pick IRC channel..."
CHAN=$(TEXT_PICKER "IRC Channel (#channel)" "#testchannel")
case $? in
    $DUCKYSCRIPT_CANCELLED|$DUCKYSCRIPT_REJECTED|$DUCKYSCRIPT_ERROR)
        exit 0
        ;;
esac

LOG white "Nick: $NICK"
LOG white "Channel: $CHAN"

################################
# Main loop (runs until payload is stopped)
################################
while :; do
    LOG white "Connecting to $SERVER..."
    
    exec 3<>/dev/tcp/$SERVER/$PORT || {
        LOG red "Connection failed, retrying in 10s..."
        sleep 10
        continue
    }

    # Register
    echo "NICK $NICK" >&3
    echo "USER $NICK 0 * :Pineapple Pager IRC" >&3
    sleep 3
    echo "JOIN $CHAN" >&3

    LOG green "Joined $CHAN"

    ################################
    # IRC receive loop
    ################################
    while read -r line <&3; do

        # Respond to PINGs
        case "$line" in
            PING*)
                echo "PONG ${line#PING }" >&3
                continue
                ;;
        esac

        # Only handle PRIVMSG lines
        echo "$line" | grep -q "PRIVMSG" || continue

        # Extract nick
        USER=$(echo "$line" | awk -F'!' '{print substr($1,2)}')

        # Extract message
        MSG=$(echo "$line" | sed -n 's/^:[^!]*![^ ]* PRIVMSG [^ ]* :\(.*\)$/\1/p')

        # Skip empty parses
        [ -z "$USER" ] || [ -z "$MSG" ] && continue

        # Display message on Pager
        LOG white "<$USER> $MSG"

        ################################
        # Reply flow
        ################################
        sleep 5
        LOG green "Launching text picker..."
        resp=$(TEXT_PICKER "Reply to $USER" "OK")

        case $? in
            $DUCKYSCRIPT_CANCELLED)
                LOG red "Reply cancelled"
                continue
                ;;
            $DUCKYSCRIPT_REJECTED)
                LOG red "Reply rejected"
                continue
                ;;
            $DUCKYSCRIPT_ERROR)
                LOG red "Picker error"
                continue
                ;;
        esac

        LOG green "Sending reply"
        echo "PRIVMSG $CHAN :$resp" >&3

    done

    LOG red "Disconnected — reconnecting in 5s..."
    sleep 5
done
