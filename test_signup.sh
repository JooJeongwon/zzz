#!/bin/bash
echo "Testing User Registration..."
curl -v -X POST http://localhost:8080/api/v1/users/register \
     -H "Content-Type: application/json" \
     -d '{
           "email": "test@zzz.com",
           "password": "password123",
           "nickname": "TestUser"
         }'
echo -e "\n\nDone."
