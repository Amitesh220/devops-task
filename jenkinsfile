pipeline {
  agent any

  environment {
    AWS_REGION = 'ap-south-1'
    IMAGE = "${env.DOCKERHUB_USER}/devops-task:${env.GIT_COMMIT.take(8)}"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install & Test') {
      steps {
        sh 'npm ci'
        sh 'npm test || true'
      }
    }

    stage('Build Docker Image') {
      steps {
        withCredentials([usernamePassword(
            credentialsId: 'dockerhub-creds',
            usernameVariable: 'DOCKERHUB_USER',
            passwordVariable: 'DOCKERHUB_PASS'
        )]) {
          sh '''
            docker build -t $DOCKERHUB_USER/devops-task:${GIT_COMMIT::8} .
            echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin
            docker push $DOCKERHUB_USER/devops-task:${GIT_COMMIT::8}
          '''
        }
      }
    }

    stage('Deploy to AWS (ECS)') {
      steps {
        withCredentials([usernamePassword(
            credentialsId: 'aws-creds',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
          sh '''
            export AWS_REGION=ap-south-1
            aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
            aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
            aws configure set region $AWS_REGION

            aws ecs update-service --cluster my-ecs-cluster \
                                   --service my-ecs-service \
                                   --force-new-deployment
          '''
        }
      }
    }
  }

  post {
    always {
      cleanWs()
    }
  }
}
