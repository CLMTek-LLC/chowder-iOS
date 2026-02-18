#!/bin/bash

# APNs Push Notification Script for Live Activities
# Usage: ./send_push.sh [start|update|update2|end]

TEAM_ID="433N42F295"
KEY_ID="73WH9U42PA"
KEY_FILE="/Users/vedantgurav/Downloads/AuthKey_73WH9U42PA.p8"
BUNDLE_ID="app.chowder.Chowder"
PUSH_TOKEN="80eacb50147ef7f80c6f2fc8654a84efb6ceeee16290b8e346a51ac145e0528eb4c5b4d30f5f181374012f1e8e754efbda706be8290cc887df8e3d989941bf4b3f070aa20909141d018af839d82401b5"

# Generate JWT
generate_jwt() {
    local header=$(printf '{"alg":"ES256","kid":"%s"}' "$KEY_ID" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
    local now=$(date +%s)
    local claims=$(printf '{"iss":"%s","iat":%d}' "$TEAM_ID" "$now" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
    local header_claims="$header.$claims"
    local signature=$(printf '%s' "$header_claims" | openssl dgst -sha256 -sign "$KEY_FILE" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
    echo "$header_claims.$signature"
}

JWT=$(generate_jwt)

# Determine which payload to send
ACTION=${1:-start}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

case $ACTION in
    start)
        PAYLOAD_FILE="$SCRIPT_DIR/start_activity.json"
        ;;
    update)
        PAYLOAD_FILE="$SCRIPT_DIR/update_activity.json"
        ;;
    update2)
        PAYLOAD_FILE="$SCRIPT_DIR/update_activity_2.json"
        ;;
    end)
        PAYLOAD_FILE="$SCRIPT_DIR/end_activity.json"
        ;;
    *)
        echo "Usage: $0 [start|update|update2|end]"
        exit 1
        ;;
esac

# Update timestamps in payload to current time
CURRENT_TIMESTAMP=$(date +%s)
STALE_TIMESTAMP=$((CURRENT_TIMESTAMP + 3600))
DISMISSAL_TIMESTAMP=$((CURRENT_TIMESTAMP + 7200))
PAYLOAD=$(cat "$PAYLOAD_FILE" | sed "s/\"timestamp\": [0-9]*/\"timestamp\": $CURRENT_TIMESTAMP/" | sed "s/\"stale-date\": [0-9]*/\"stale-date\": $STALE_TIMESTAMP/" | sed "s/\"dismissal-date\": [0-9]*/\"dismissal-date\": $DISMISSAL_TIMESTAMP/")

echo "Sending $ACTION notification..."
echo "Payload: $PAYLOAD"
echo ""

curl -v \
    --http2 \
    --header "authorization: bearer $JWT" \
    --header "apns-topic: ${BUNDLE_ID}.push-type.liveactivity" \
    --header "apns-push-type: liveactivity" \
    --header "apns-priority: 10" \
    --header "apns-expiration: 0" \
    --data "$PAYLOAD" \
    "https://api.sandbox.push.apple.com/3/device/$PUSH_TOKEN"

echo ""
echo "Done!"
