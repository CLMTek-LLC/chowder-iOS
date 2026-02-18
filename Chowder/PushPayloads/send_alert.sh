#!/bin/bash

# Simple alert push notification test
# This tests if basic push notifications work at all

TEAM_ID="433N42F295"
KEY_ID="73WH9U42PA"
KEY_FILE="/Users/vedantgurav/Downloads/AuthKey_73WH9U42PA.p8"
BUNDLE_ID="app.chowder.Chowder"

# You need to get a regular push token from the app
# For now, we'll try with the push-to-start token (might not work)
PUSH_TOKEN="80c9b07b93d5fe0a6852a1783b81d9ac375c040955d709d0428330be3b68f0414941f4252182aed8bf7c366699778d9c3a2a9dbb79801a80b69598824140acd4c2ab32148442956a1a9329c460bbddde"

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
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD=$(cat "$SCRIPT_DIR/test_alert.json")

echo "Sending test alert notification..."
echo "Payload: $PAYLOAD"
echo ""

curl -v \
    --http2 \
    --header "authorization: bearer $JWT" \
    --header "apns-topic: ${BUNDLE_ID}" \
    --header "apns-push-type: alert" \
    --header "apns-priority: 10" \
    --data "$PAYLOAD" \
    "https://api.sandbox.push.apple.com/3/device/$PUSH_TOKEN"

echo ""
echo "Done!"
