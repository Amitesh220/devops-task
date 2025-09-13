pipeline {
  agent any
  environment {
    DOCKER_IMAGE = "amitesh220/devops-task"   
    AWS_REGION = "ap-south-1"
    CLUSTER_NAME = "devops-task-cluster"      
    SERVICE_NAME = "devops-task-service"      
    CONTAINER_NAME = "devops-task"
    CONTAINER_PORT = "3000"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build & Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            set -e
            TAG=$(echo ${GIT_COMMIT} | cut -c1-8)
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker build -t ${DOCKER_IMAGE}:${TAG} .
            docker push ${DOCKER_IMAGE}:${TAG}
            docker tag ${DOCKER_IMAGE}:${TAG} ${DOCKER_IMAGE}:latest
            docker push ${DOCKER_IMAGE}:latest
            echo "IMAGE_URI=${DOCKER_IMAGE}:${TAG}" > image.properties
          '''
        }
        stash includes: 'image.properties', name: 'imageprops'
      }
    }

    stage('Deploy to ECS') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          unstash 'imageprops'
          sh '''
            set -e
            export AWS_REGION=${AWS_REGION}
            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
            source image.properties

            # get AWS account id
            AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

            # Prepare ECS task definition JSON
            cat > taskdef.json <<EOF
{
  "family": "${CONTAINER_NAME}",
  "networkMode": "awsvpc",
  "executionRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CONTAINER_NAME}-ecs-exec-role",
  "taskRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CONTAINER_NAME}-task-role",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "${CONTAINER_NAME}",
      "image": "${IMAGE_URI}",
      "essential": true,
      "portMappings": [
        { "containerPort": ${CONTAINER_PORT}, "protocol": "tcp" }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/${CONTAINER_NAME}",
          "awslogs-region": "${AWS_REGION}",
          "awslogs-stream-prefix": "${CONTAINER_NAME}"
        }
      }
    }
  ]
}
EOF

            # Register ECS task definition
            TASK_DEF_ARN=$(aws ecs register-task-definition --cli-input-json file://taskdef.json --query 'taskDefinition.taskDefinitionArn' --output text)
            echo "Registered Task Definition: $TASK_DEF_ARN"

            # Update ECS service with new task definition
            aws ecs update-service --cluster ${CLUSTER_NAME} --service ${SERVICE_NAME} --task-definition ${TASK_DEF_ARN} --force-new-deployment
            echo "ECS Service Updated: ${SERVICE_NAME}"
          '''
        }
      }
    }
  }

  post {
    always { cleanWs() }
  }
}
