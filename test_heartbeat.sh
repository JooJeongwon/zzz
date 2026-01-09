#!/bin/bash
echo "Testing Heartbeat..."
curl -v -X POST http://localhost:8080/api/v1/users/heartbeat \
     -H "Content-Type: application/json" \
     -H "X-User-Id: 1" \
     -d '{
           "batteryLevel": 85,
           "isScreenOn": true
         }'
echo -e "\n\nDone."
