pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE_NAME = 'manishvishwa801/easyshop-dhi'
        DOCKER_MIGRATION_IMAGE_NAME = 'manishvishwa801/easyshop-migration'
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
        AWS_CREDENTIALS = credentials('aws-credentials')
        GITHUB_CREDENTIALS = credentials('github-credentials')
        GIT_BRANCH = "tf-DevOps"
    }
    
    stages {
        stage('Check for CI Skip') {
            steps {
                script {
                    def commitMessage = sh(script: 'git log -1 --pretty=%B', returnStdout: true).trim()
                    echo "Commit message: ${commitMessage}"
                    if (commitMessage.contains('[ci skip]') || commitMessage.contains('[skip ci]')) {
                        echo "Found CI skip directive in commit message, aborting build"
                        currentBuild.result = 'ABORTED'
                        error("Build skipped due to [ci skip] directive")
                    }
                }
            }
        }
        
        stage('Cleanup Workspace') {
            steps {
                echo "Cleaning workspace..."
                deleteDir()
            }
        }
        
        stage('Clone Repository') {
            steps {
                echo "Cloning repository from ${GIT_BRANCH}..."
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "${GIT_BRANCH}"]],
                    userRemoteConfigs: [[url: 'https://github.com/manishvishwakarma89/EKS-easyshop-site.git']]
                ])
            }
        }
        
        stage('Build Docker Images') {
            parallel {
                stage('Build Main App Image') {
                    steps {
                        script {
                            echo "Building Docker image: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
                            sh """
                                docker build -f Dockerfile -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} .
                            """
                        }
                    }
                }
                
                stage('Build Migration Image') {
                    steps {
                        script {
                            echo "Building Migration image: ${DOCKER_MIGRATION_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
                            sh """
                                docker build -f scripts/Dockerfile.migration -t ${DOCKER_MIGRATION_IMAGE_NAME}:${DOCKER_IMAGE_TAG} .
                            """
                        }
                    }
                }
            }
        }
        
        stage('Run Unit Tests') {
            steps {
                echo "Running unit tests..."
                sh """
                    echo "Test stage - add your test commands here"
                    # sh 'npm test'
                    # sh 'python -m pytest'
                """
            }
        }
        
        stage('Security Scan with Trivy') {
            steps {
                echo "Running Trivy security scan..."
                sh """
                    mkdir -p trivy-results
                    
                    echo "Scanning main application image..."
                    trivy image --severity HIGH,CRITICAL \
                        --format json \
                        --output trivy-results/main-app.json \
                        ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} || true
                    
                    echo "Scanning migration image..."
                    trivy image --severity HIGH,CRITICAL \
                        --format json \
                        --output trivy-results/migration.json \
                        ${DOCKER_MIGRATION_IMAGE_NAME}:${DOCKER_IMAGE_TAG} || true
                """
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-results/*.json', allowEmptyArchive: true
                }
            }
        }
        
        stage('Push Docker Images') {
            parallel {
                stage('Push Main App Image') {
                    steps {
                        script {
                            withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                                sh """
                                    echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                                    docker push ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                                    docker logout
                                """
                            }
                        }
                    }
                }
                
                stage('Push Migration Image') {
                    steps {
                        script {
                            withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                                sh """
                                    echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                                    docker push ${DOCKER_MIGRATION_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                                    docker logout
                                """
                            }
                        }
                    }
                }
            }
        }
        
        stage('Update Kubernetes Manifests') {
            steps {
                echo "Updating Kubernetes manifests..."
                withCredentials([usernamePassword(credentialsId: 'github-credentials', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                    sh """
                        git config user.name "Jenkins CI"
                        git config user.email "iemafzalhassan@gmail.com"
                        
                        # Update image tags in YAML files
                        find kubernetes -name '*.yaml' -o -name '*.yml' | xargs sed -i 's|${DOCKER_IMAGE_NAME}:latest|${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}|g' || true
                        find kubernetes -name '*.yaml' -o -name '*.yml' | xargs sed -i 's|${DOCKER_MIGRATION_IMAGE_NAME}:latest|${DOCKER_MIGRATION_IMAGE_NAME}:${DOCKER_IMAGE_TAG}|g' || true
                        
                        git add kubernetes || true
                        git commit -m "Update image tags to ${DOCKER_IMAGE_TAG}" || true
                        
                        git push https://\${GIT_USER}:\${GIT_TOKEN}@github.com/manishvishwakarma89/EKS-easyshop-site.git ${GIT_BRANCH} || true
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "=== BUILD SUMMARY ==="
            echo "Project: EasyShop"
            echo "Main Image: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
            echo "Migration Image: ${DOCKER_MIGRATION_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
            echo "Build Status: ${currentBuild.result}"
            echo "===================="
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}