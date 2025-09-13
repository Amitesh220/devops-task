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
      steps { 
        checkout scm 
      }
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
          sh '''#!/bin/bash
            set -e
            export AWS_REGION=${AWS_REGION}
            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
            
            # Source the image properties file
            source image.properties
            
            # Check if AWS CLI is installed, if not install it
            if ! command -v aws &> /dev/null; then
                echo "AWS CLI not found, installing..."
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip -q awscliv2.zip
                sudo ./aws/install
            fi
            
            # Verify AWS credentials
            echo "Verifying AWS credentials..."
            aws sts get-caller-identity
            
            # Get AWS account ID
            AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
            echo "AWS Account ID: ${AWS_ACCOUNT_ID}"
            
            # Create CloudWatch log group if it doesn't exist
            aws logs create-log-group --log-group-name "/ecs/${CONTAINER_NAME}" --region ${AWS_REGION} || echo "Log group already exists"
            
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
        { 
          "containerPort": ${CONTAINER_PORT}, 
          "protocol": "tcp" 
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/${CONTAINER_NAME}",
          "awslogs-region": "${AWS_REGION}",
          "awslogs-stream-prefix": "${CONTAINER_NAME}"
        }
      },
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        }
      ]
    }
  ]
}
EOF
            
            echo "Task Definition JSON created:"
            cat taskdef.json
            
            # Register ECS task definition
            echo "Registering new task definition..."
            TASK_DEF_ARN=$(aws ecs register-task-definition --cli-input-json file://taskdef.json --query 'taskDefinition.taskDefinitionArn' --output text)
            echo "Registered Task Definition: $TASK_DEF_ARN"
            
            # Check if ECS cluster exists
            if ! aws ecs describe-clusters --clusters ${CLUSTER_NAME} --query 'clusters[0].status' --output text | grep -q "ACTIVE"; then
                echo "Creating ECS cluster: ${CLUSTER_NAME}"
                aws ecs create-cluster --cluster-name ${CLUSTER_NAME}
                
                # Wait for cluster to be active
                echo "Waiting for cluster to be active..."
                aws ecs wait cluster-active --clusters ${CLUSTER_NAME}
            fi
            
            # Check if ECS service exists, if not create it
            if ! aws ecs describe-services --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME} --query 'services[0].status' --output text | grep -q "ACTIVE"; then
                echo "Service does not exist or is not active. Creating service: ${SERVICE_NAME}"
                
                # You'll need to replace these subnet and security group IDs with your actual values
                # For now, this will fail and show you what needs to be configured
                aws ecs create-service \
                  --cluster ${CLUSTER_NAME} \
                  --service-name ${SERVICE_NAME} \
                  --task-definition ${TASK_DEF_ARN} \
                  --desired-count 1 \
                  --launch-type FARGATE \
                  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxxxxxxx],securityGroups=[sg-xxxxxxxx],assignPublicIp=ENABLED}" \
                  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:${AWS_REGION}:${AWS_ACCOUNT_ID}:targetgroup/your-target-group,containerName=${CONTAINER_NAME},containerPort=${CONTAINER_PORT}" || echo "Service creation failed - please configure networking manually"
            else
                # Update existing ECS service with new task definition
                echo "Updating existing ECS service: ${SERVICE_NAME}"
                aws ecs update-service \
                  --cluster ${CLUSTER_NAME} \
                  --service ${SERVICE_NAME} \
                  --task-definition ${TASK_DEF_ARN} \
                  --force-new-deployment
            fi
            
            echo "ECS Deployment initiated for service: ${SERVICE_NAME}"
            
            # Wait for deployment to complete (optional)
            echo "Waiting for service to stabilize..."
            aws ecs wait services-stable --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME}
            echo "Deployment completed successfully!"
          '''
        }
      }
    }
  }
  post {
    always { 
      cleanWs() 
    }
    success {
      echo 'Pipeline completed successfully!'
    }
    failure {
      echo 'Pipeline failed. Check the logs for details.'
    }
  }
}
