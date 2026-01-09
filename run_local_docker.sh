#!/bin/bash
echo "🚀 ZZZ Local Environment Setup via Docker 🐳"

# Check Docker
if ! docker info > /dev/null 2>&1; then
  echo "Error: Docker is not running. Please start Docker Desktop and try again."
  exit 1
fi

echo "📦 Building Core Service..."
# Optional: Pre-build locally if you want to skip Docker build context upload time, 
# but docker-compose build handles it fine.
# cd backend/core-service && ./gradlew bootJar && cd ../..

echo "📦 Building AI Service..."

echo "🐳 Starting Docker Compose Stack..."
cd infra
docker-compose down
docker-compose up --build -d

echo "✅ Stack is running!"
echo "   - Core Service: http://localhost:8080"
echo "   - AI Service:   http://localhost:8000"
echo "   - MySQL:        localhost:3306"
echo "   - Redis:        localhost:6379"
echo "   - Mongo:        localhost:27017"
echo "   - RabbitMQ:     http://localhost:15672"

echo "📜 To check logs: cd infra && docker-compose logs -f"
