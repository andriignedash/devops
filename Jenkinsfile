pipeline {
    agent {
        label 'kaniko'
    }
    
    environment {
        ECR_REGISTRY = "${env.ECR_REGISTRY ?: 'XXXXXXXXXXXX.dkr.ecr.us-west-2.amazonaws.com'}"
        ECR_REPOSITORY = "${env.ECR_REPOSITORY ?: 'lesson-8-9-ecr'}"
        AWS_REGION = "${env.AWS_REGION ?: 'us-west-2'}"
        
        GITOPS_REPO_URL = "${env.GITOPS_REPO_URL ?: 'https://github.com/andriignedash/devops-gitops.git'}"
        GITOPS_BRANCH = "${env.GITOPS_BRANCH ?: 'main'}"
        GITOPS_VALUES_PATH = "${env.GITOPS_VALUES_PATH ?: 'charts/django-app/values.yaml'}"
        
        IMAGE_TAG = "${env.GIT_COMMIT?.take(7) ?: 'latest'}"
        IMAGE_FULL = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
        IMAGE_LATEST = "${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
    }
    
    stages {
        stage('Checkout') {
            steps {
                container('git') {
                    script {
                        echo "Checking out code..."
                        checkout scm
                        
                        env.IMAGE_TAG = sh(
                            script: 'git rev-parse --short HEAD',
                            returnStdout: true
                        ).trim()
                        
                        env.IMAGE_FULL = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
                        
                        echo "Building image: ${IMAGE_FULL}"
                    }
                }
            }
        }
        
        stage('Build & Push to ECR') {
            steps {
                container('kaniko') {
                    script {
                        echo "Building Docker image with Kaniko..."
                        
                        sh """
                            echo '{"credsStore":"ecr-login"}' > /kaniko/.docker/config.json
                        """
                        
                        sh """
                            /kaniko/executor \
                                --context=${WORKSPACE}/docker-django-nginx/app \
                                --dockerfile=${WORKSPACE}/docker-django-nginx/app/Dockerfile \
                                --destination=${IMAGE_FULL} \
                                --destination=${IMAGE_LATEST} \
                                --cache=true \
                                --compressed-caching=false \
                                --snapshot-mode=redo \
                                --log-format=text
                        """
                        
                        echo "Image pushed successfully: ${IMAGE_FULL}"
                        echo "Latest tag updated: ${IMAGE_LATEST}"
                    }
                }
            }
        }
        
        stage('Update GitOps Repo') {
            steps {
                container('git') {
                    script {
                        echo "Updating GitOps repository..."
                        
                        withCredentials([string(credentialsId: 'github_pat', variable: 'GITHUB_TOKEN')]) {
                            sh """
                                git config --global user.name "Jenkins CI"
                                git config --global user.email "jenkins@ci.local"
                                git config --global --add safe.directory /home/jenkins/agent/workspace/*
                                
                                rm -rf gitops-repo
                                
                                GITOPS_URL_WITH_TOKEN=\$(echo ${GITOPS_REPO_URL} | sed "s|https://|https://${GITHUB_TOKEN}@|")
                                
                                git clone --branch ${GITOPS_BRANCH} --depth 1 \${GITOPS_URL_WITH_TOKEN} gitops-repo
                                
                                cd gitops-repo
                                
                                if [ -f "${GITOPS_VALUES_PATH}" ]; then
                                    sed -i "s|tag:.*|tag: \\"${IMAGE_TAG}\\"|g" ${GITOPS_VALUES_PATH}
                                    
                                    echo "Updated values.yaml:"
                                    grep -A 2 "image:" ${GITOPS_VALUES_PATH}
                                    
                                    git add ${GITOPS_VALUES_PATH}
                                    git commit -m "Update image tag to ${IMAGE_TAG}" || echo "No changes to commit"
                                    git push origin ${GITOPS_BRANCH}
                                    
                                    echo "GitOps repo updated successfully!"
                                else
                                    echo "ERROR: values.yaml not found at ${GITOPS_VALUES_PATH}"
                                    exit 1
                                fi
                            """
                        }
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "Pipeline completed successfully!"
            echo "Image: ${IMAGE_FULL}"
            echo "GitOps repo updated with tag: ${IMAGE_TAG}"
            echo "Argo CD will automatically sync the changes."
        }
        failure {
            echo "Pipeline failed. Check logs for details."
        }
        always {
            echo "Cleaning up workspace..."
            cleanWs()
        }
    }
}
