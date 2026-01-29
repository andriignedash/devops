pipeline {
    agent {
        label 'kaniko'
    }
    
    options {
        skipDefaultCheckout(true)
    }
    
    environment {
        AWS_REGION     = "us-west-2"
        ECR_REGISTRY   = "082228066503.dkr.ecr.us-west-2.amazonaws.com"
        ECR_REPOSITORY = "lesson-8-9-ecr"
        GITOPS_REPO_URL    = "https://github.com/andriignedash/devops-gitops.git"
        GITOPS_BRANCH      = "main"
        GITOPS_VALUES_PATH = "charts/django-app/values.yaml"
    }
    
    stages {
        stage('Checkout') {
            steps {
                container('git') {
                    checkout scm
                    script {
                        sh 'git config --global --add safe.directory "$(pwd)"'
                        env.IMAGE_TAG = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                        echo "Image tag: ${env.IMAGE_TAG}"
                    }
                }
            }
        }
        
        stage('Build & Push to ECR') {
            steps {
                container('kaniko') {
                    sh """
                        echo '{"credsStore":"ecr-login"}' > /kaniko/.docker/config.json
                        /kaniko/executor \
                            --context=${WORKSPACE}/docker-django-nginx/app \
                            --dockerfile=${WORKSPACE}/docker-django-nginx/app/Dockerfile \
                            --destination=${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} \
                            --destination=${ECR_REGISTRY}/${ECR_REPOSITORY}:latest \
                            --cache=true \
                            --compressed-caching=false \
                            --snapshot-mode=redo \
                            --log-format=text
                    """
                    echo "Pushed: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
                }
            }
        }
        
        stage('Update GitOps Repo') {
            steps {
                container('git') {
                    withCredentials([string(credentialsId: 'github_pat', variable: 'GITHUB_TOKEN')]) {
                        sh """
                            git config --global user.name "Jenkins CI"
                            git config --global user.email "jenkins@ci.local"
                            git config --global --add safe.directory "*"
                            
                            rm -rf gitops-repo
                            git clone --branch ${GITOPS_BRANCH} --depth 1 https://\${GITHUB_TOKEN}@github.com/andriignedash/devops-gitops.git gitops-repo
                            
                            cd gitops-repo
                            sed -i "s|tag:.*|tag: \\"${IMAGE_TAG}\\"|g" ${GITOPS_VALUES_PATH}
                            
                            git add ${GITOPS_VALUES_PATH}
                            git commit -m "Update image tag to ${IMAGE_TAG}" || echo "No changes"
                            git push origin ${GITOPS_BRANCH}
                        """
                    }
                    echo "GitOps updated with tag: ${IMAGE_TAG}"
                }
            }
        }
    }
    
    post {
        success {
            echo "Pipeline SUCCESS: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
        }
        failure {
            echo "Pipeline FAILED"
        }
    }
}
