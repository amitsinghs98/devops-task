pipeline {
    agent any

    environment {
        AWS_REGION        = "ap-south-1"
        AWS_CREDENTIALS   = "aws-credentials"
        ACCOUNT_ID        = "539247483501"
        ECR_REPO          = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/logo-server-repo"
        IMAGE_NAME        = "logo-server"
        SONARQUBE         = "sonar-scanner"
        SONARQUBE_TOKEN   = "sonar-scanner"
        IMAGE_TAG         = "${env.BRANCH_NAME ?: 'unknown'}-${env.BUILD_NUMBER}"
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

        stage('Install Dependencies') {
            steps {
                dir('app') {
                    sh 'npm install'
                }
            }
        }

        stage('Run Lint') {
            steps {
                dir('app') {
                    sh 'npm run lint || true'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -f Dockerfile -t $ECR_REPO:$IMAGE_TAG .'
            }
        }

        stage('Security Scan with Trivy') {
            steps {
                sh '''
                    trivy image --exit-code 0 --severity MEDIUM,HIGH,CRITICAL $ECR_REPO:$IMAGE_TAG
                '''
            }
        }

        stage('Push to ECR') {
            when {
                anyOf {
                    branch 'dev'
                    branch 'main'
                    branch 'test-jenkinsfile-changes'
                }
            }
            steps {
                script {
                    withAWS(credentials: "${AWS_CREDENTIALS}") {
                        sh """
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                            docker push ${ECR_REPO}:${IMAGE_TAG}
                        """
                    }
                }
            }
        }

        stage('Terraform') {
            steps {
                dir('infra') {
                    withCredentials([aws(credentialsId: 'aws-credentials', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh '''
                            terraform init -input=false -backend-config="key=ecs/${BRANCH_NAME}/terraform.tfstate"
                            terraform plan -input=false -var="branch=${BRANCH_NAME}"
                        '''

                        script {
                            if (env.BRANCH_NAME == 'main' && env.CHANGE_ID == null) {
                                sh '''
                                    terraform apply -auto-approve -input=false -var="branch=${BRANCH_NAME}"
                                '''
                            } else {
                                echo "Skipping terraform apply (PR or dev branch)"
                            }
                        }
                    }
                }
            }
        }
    }
}
