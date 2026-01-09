#!/bin/bash

# Base URL
URL="http://localhost:8080/api/v1"

# Utils
TIMESTAMP=$(date +%s)
EMAIL_A="userA_$TIMESTAMP@test.com"
EMAIL_B="userB_$TIMESTAMP@test.com"

function get_json_value() {
  echo $1 | python3 -c "import sys, json; print(json.load(sys.stdin)['$2'])"
}

echo "1. Register & Login User A..."
# Register A
curl -s -X POST $URL/users/register -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL_A\", \"password\": \"1234\", \"nickname\": \"UserA\"}" > /dev/null

# Login A
RESP_A=$(curl -s -X POST $URL/users/login -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL_A\", \"password\": \"1234\"}")
echo "DEBUG RESP_A: $RESP_A"
TOKEN_A=$(get_json_value "$RESP_A" "accessToken")
ID_A=$(get_json_value "$RESP_A" "userId")
echo "User A Token: ${TOKEN_A:0:10}..."

echo "2. Register & Login User B..."
# Register B
curl -s -X POST $URL/users/register -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL_B\", \"password\": \"1234\", \"nickname\": \"UserB\"}" > /dev/null

# Login B
RESP_B=$(curl -s -X POST $URL/users/login -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL_B\", \"password\": \"1234\"}")
TOKEN_B=$(get_json_value "$RESP_B" "accessToken")
ID_B=$(get_json_value "$RESP_B" "userId")
echo "User B Token: ${TOKEN_B:0:10}..."

echo "3. Connect Couple..."
# A creates invite
INVITE_RESP=$(curl -s -X POST $URL/couples/invite -H "Authorization: Bearer $TOKEN_A")
CODE=$(get_json_value "$INVITE_RESP" "code")
echo "Invite Code: $CODE"

# B connects
curl -s -X POST $URL/couples/connect -H "Authorization: Bearer $TOKEN_B" -H "Content-Type: application/json" \
  -d "{\"code\": \"$CODE\"}" > /dev/null
echo "Couple connected."

echo "4. User B sets status to SLEEP..."
curl -s -X POST $URL/users/status -H "Authorization: Bearer $TOKEN_B" -H "Content-Type: application/json" \
  -d "{\"status\": \"SLEEP\"}" > /dev/null
echo "Status updated."

echo "5. User A sends message to User B..."
# Send "Hello? Are you sleeping?"
curl -s -X POST $URL/chat/send -H "Authorization: Bearer $TOKEN_A" -H "Content-Type: application/json" \
  -d "{\"receiverId\": $ID_B, \"content\": \"Hello? Are you sleeping?\"}" > /dev/null
echo "Message sent."

echo "Wait for AI processing (2s)..."
sleep 2

echo "6. User A checks chat history for AI response..."
HISTORY=$(curl -s -X GET "$URL/chat/history?partnerId=$ID_B&page=0&size=10" -H "Authorization: Bearer $TOKEN_A")

# Check if isAiGenerated is true in the response
echo $HISTORY | python3 -c "
import sys, json
data = json.load(sys.stdin)
messages = data['content']
ai_msgs = [m for m in messages if m.get('isAiGenerated') == True]
if ai_msgs:
    print('SUCCESS: AI Response Found!')
    print('AI Said:', ai_msgs[0]['content'])
else:
    print('FAIL: No AI Response found.')
    print('Recent messages:', messages)
"
