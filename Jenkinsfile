pipeline {
    agent any

    environment {
        AWS_REGION  = "ap-south-1"
        ACCOUNT_ID  = "539247483501"     // Static & safe to keep
        ECR_REPO    = "539247483501.dkr.ecr.ap-south-1.amazonaws.com/logo-server-repo"
        IMAGE_NAME  = "logo-server"
        SONARQUBE   = "sonar-scanner" // Jenkins SonarQube config name
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Checkout') {
            steps {
                  git branch: 'test-jenkinsfile-changes', credentialsId: 'git-pat', url: 'https://github.com/amitsinghs98/devops-task.git'
            }
        }
         stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t $IMAGE_NAME:$BRANCH_NAME .'
                }
            }
        }
           stage('Security Scan with Trivy') {
            steps {
                sh '''
                trivy image --exit-code 0 --severity MEDIUM,HIGH,CRITICAL $IMAGE_NAME:$BRANCH_NAME
                '''
            }
        }
    }
}