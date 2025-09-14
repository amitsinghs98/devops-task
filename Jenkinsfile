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
        BRANCH            = "${env.BRANCH_NAME ?: env.GIT_BRANCH ?: 'main'}"
        IMAGE_TAG         = "${BRANCH}-${env.BUILD_NUMBER}"
    }


    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "Checking out branch: ${BRANCH}"
                    git branch: "${BRANCH}", credentialsId: 'git-pat', url: 'https://github.com/amitsinghs98/devops-task.git'
                }
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
                    branch 'main'
                    branch 'dev'
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
                        script {
                            echo "DEBUG: BRANCH=${BRANCH}, CHANGE_ID=${env.CHANGE_ID}"
                        }
                        sh '''
                            terraform init -reconfigure -input=false -backend-config="key=ecs/${BRANCH}/terraform.tfstate"
                            terraform plan -input=false -var="branch=${BRANCH}"
                        '''
                        script {
                            if (BRANCH == 'main') {
                                sh '''
                                    terraform apply -auto-approve -input=false -var="branch=${BRANCH}"
                                '''
                            } else {
                                echo "Skipping terraform apply (not main branch)"
                            }
                        }
                    }
                }
            }
        }
    }
}
