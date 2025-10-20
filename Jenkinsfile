pipeline {
    agent any

    environment {
        REGISTRY_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE_NAME = "wolfie8935/myapp"
        GREEN_TAG = "green-2"
        KUBE_CONFIG = credentials('kubeconfig')
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                git 'https://github.com/Wolfie8935/blue-green.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('app/src') {
                    script {
                        echo "Building Docker image for green environment..."
                        dockerImage = docker.build("${DOCKER_IMAGE_NAME}:${GREEN_TAG}")
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    echo "Pushing Docker image to registry..."
                    docker.withRegistry('https://index.docker.io/v1/', REGISTRY_CREDENTIALS) {
                        dockerImage.push()
                    }
                }
            }
        }

        stage('Update Kubernetes Manifests') {
            steps {
                echo "Updating Kubernetes manifests..."
                // Example: sed or yq update of image tag
                bat "kubectl set image deployment/myapp myapp=${DOCKER_IMAGE_NAME}:${GREEN_TAG} --kubeconfig=${KUBE_CONFIG}"
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "Deploying to Kubernetes cluster..."
                bat "kubectl rollout restart deployment/myapp --kubeconfig=${KUBE_CONFIG}"
            }
        }

        stage('Run Smoke Tests') {
            steps {
                echo "Running smoke tests..."
                bat "curl -f http://<your-app-endpoint>:3000 || exit 1"
            }
        }

        stage('Switch Traffic') {
            steps {
                echo "Switching traffic to green deployment..."
                // Add your load balancer or Ingress switch here
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed!'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
    }
}
