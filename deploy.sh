#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# ---------------------------------------------
# 🫧 Basic config
# ---------------------------------------------
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
AWS_REGION="us-east-1"
REPO_NAME="ecs-node-app"
IMAGE_TAG="latest"

CLUSTER_NAME="ecs-node-cluster"
SERVICE_NAME="ecs-node-app-service"

# ---------------------------------------------
# 🐳 1️⃣ Build Docker image
# ---------------------------------------------
echo "🚀 Building Docker image..."
docker build -t $REPO_NAME:$IMAGE_TAG .

# ---------------------------------------------
# 🏷️ 2️⃣ Tag & push to ECR
# ---------------------------------------------
echo "🔑 Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | \
docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

echo "🏷️ Tagging image..."
docker tag $REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG

echo "📤 Pushing image to ECR..."
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG

# ---------------------------------------------
# 🗂️ 4️⃣ Register task def revision
# ---------------------------------------------
echo "📡 Registering new task definition..."

echo "📝 Generating task definition file with variables..."

cat <<EOF > $SCRIPT_DIR/task-def.json
{
  "family": "$REPO_NAME",
  "networkMode": "awsvpc",
  "cpu": "256",
  "memory": "512",
  "requiresCompatibilities": ["FARGATE"],
  "executionRoleArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "$REPO_NAME",
      "image": "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/$REPO_NAME-logs",
          "awslogs-region": "$AWS_REGION",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ],
  "runtimePlatform": {
    "cpuArchitecture": "X86_64",
    "operatingSystemFamily": "LINUX"
  }
}
EOF


aws ecs register-task-definition --cli-input-json file://$SCRIPT_DIR/task-def.json




# ---------------------------------------------
# 🚀 5️⃣ Update ECS service
# ---------------------------------------------
echo "🔄 Updating ECS service to use new task definition..."
aws ecs update-service \
--cluster $CLUSTER_NAME \
--service $SERVICE_NAME \
--task-definition $REPO_NAME

echo "✅ Deploy complete!"

# ---------------------------------------------
# ⚡ 6️⃣ Show running tasks (optional)
# ---------------------------------------------
echo "🔍 Listing running tasks..."
aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME

echo "🫶 Done!"
