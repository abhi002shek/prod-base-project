pipeline {
    agent any
    
    tools {
        nodejs 'nodejs23'
    }
    
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '616919332376'
        ECR_FRONTEND = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/prod-base-project/frontend"
        ECR_BACKEND = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/prod-base-project/backend"
        EKS_CLUSTER = 'production-prod-base-project-eks'
    }
    
    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/abhi002shek/prod-base-project.git'
            }
        }
        
        stage('Install Dependencies') {
            parallel {
                stage('Frontend Dependencies') {
                    steps {
                        dir('application/3-Tier-DevSecOps-Mega-Project/client') {
                            sh 'npm install'
                        }
                    }
                }
                stage('Backend Dependencies') {
                    steps {
                        dir('application/3-Tier-DevSecOps-Mega-Project/api') {
                            sh 'npm install'
                        }
                    }
                }
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectKey=prod-base-project \
                        -Dsonar.projectName=prod-base-project \
                        -Dsonar.sources=application/3-Tier-DevSecOps-Mega-Project \
                        -Dsonar.exclusions=**/node_modules/**,**/coverage/**,**/*.log
                    '''
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    timeout(time: 5, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                    }
                }
            }
        }
        
        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs --format table -o trivy-fs-report.html application/3-Tier-DevSecOps-Mega-Project'
            }
        }
        
        stage('Build & Scan Docker Images') {
            parallel {
                stage('Frontend') {
                    stages {
                        stage('Build Frontend') {
                            steps {
                                dir('application/3-Tier-DevSecOps-Mega-Project/client') {
                                    sh "docker build -t ${ECR_FRONTEND}:${BUILD_NUMBER} ."
                                    sh "docker tag ${ECR_FRONTEND}:${BUILD_NUMBER} ${ECR_FRONTEND}:latest"
                                }
                            }
                        }
                        stage('Scan Frontend') {
                            steps {
                                sh "trivy image --format table -o trivy-frontend-report.html ${ECR_FRONTEND}:${BUILD_NUMBER}"
                            }
                        }
                    }
                }
                stage('Backend') {
                    stages {
                        stage('Build Backend') {
                            steps {
                                dir('application/3-Tier-DevSecOps-Mega-Project/api') {
                                    sh "docker build -t ${ECR_BACKEND}:${BUILD_NUMBER} ."
                                    sh "docker tag ${ECR_BACKEND}:${BUILD_NUMBER} ${ECR_BACKEND}:latest"
                                }
                            }
                        }
                        stage('Scan Backend') {
                            steps {
                                sh "trivy image --format table -o trivy-backend-report.html ${ECR_BACKEND}:${BUILD_NUMBER}"
                            }
                        }
                    }
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                script {
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                        docker push ${ECR_FRONTEND}:${BUILD_NUMBER}
                        docker push ${ECR_FRONTEND}:latest
                        docker push ${ECR_BACKEND}:${BUILD_NUMBER}
                        docker push ${ECR_BACKEND}:latest
                    '''
                }
            }
        }
        
        stage('Update K8s Manifests') {
            steps {
                dir('application/k8s-prod') {
                    sh """
                        sed -i 's|image:.*frontend.*|image: ${ECR_FRONTEND}:${BUILD_NUMBER}|g' frontend.yaml
                        sed -i 's|image:.*backend.*|image: ${ECR_BACKEND}:${BUILD_NUMBER}|g' backend.yaml
                    """
                }
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                script {
                    sh '''
                        aws eks update-kubeconfig --name ${EKS_CLUSTER} --region ${AWS_REGION}
                        kubectl apply -f application/k8s-prod/00-namespace.yaml
                        kubectl apply -f application/k8s-prod/01-secrets.yaml
                        kubectl apply -f application/k8s-prod/mysql.yaml
                        sleep 30
                        kubectl apply -f application/k8s-prod/backend.yaml
                        kubectl apply -f application/k8s-prod/frontend.yaml
                        kubectl apply -f application/k8s-prod/ingress.yaml
                        kubectl apply -f application/k8s-prod/hpa.yaml
                    '''
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                sh '''
                    kubectl get pods -n production
                    kubectl get svc -n production
                    kubectl get ingress -n production
                '''
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'trivy-*.html', allowEmptyArchive: true
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}
