pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = '<YOUR_DOCKER_REGISTRY>'
        DOCKER_CREDENTIALS = 'docker-hub-credentials' // Jenkins credential ID
        KUBECONFIG_CREDENTIALS = 'kubeconfig-credentials' // Jenkins credential ID
        APP_NAME = 'myapp'
        NAMESPACE = 'production'
    }
    
    parameters {
        choice(name: 'DEPLOYMENT_TYPE', choices: ['green', 'blue'], description: 'Select deployment environment')
        choice(name: 'ACTION', choices: ['deploy', 'rollback'], description: 'Select action')
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    echo "Building Docker image for ${params.DEPLOYMENT_TYPE} environment..."
                    dir('app/src') {
                        dockerImage = docker.build("${DOCKER_REGISTRY}/${APP_NAME}:${params.DEPLOYMENT_TYPE}-${BUILD_NUMBER}")
                        dockerImage.tag("${params.DEPLOYMENT_TYPE}")
                    }
                }
            }
        }
        
        stage('Push Docker Image') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    echo 'Pushing Docker image to registry...'
                    docker.withRegistry("https://${DOCKER_REGISTRY}", "${DOCKER_CREDENTIALS}") {
                        dockerImage.push("${params.DEPLOYMENT_TYPE}-${BUILD_NUMBER}")
                        dockerImage.push("${params.DEPLOYMENT_TYPE}")
                    }
                }
            }
        }
        
        stage('Update Kubernetes Manifests') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    echo 'Updating Kubernetes deployment files...'
                    sh """
                        sed -i 's|image: .*|image: ${DOCKER_REGISTRY}/${APP_NAME}:${params.DEPLOYMENT_TYPE}|g' k8s/deployment-${params.DEPLOYMENT_TYPE}.yaml
                    """
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    echo "Deploying to ${params.DEPLOYMENT_TYPE} environment..."
                    withKubeConfig([credentialsId: "${KUBECONFIG_CREDENTIALS}"]) {
                        sh """
                            kubectl apply -f k8s/namespace.yaml
                            kubectl apply -f k8s/deployment-${params.DEPLOYMENT_TYPE}.yaml
                            kubectl rollout status deployment/myapp-${params.DEPLOYMENT_TYPE} -n ${NAMESPACE} --timeout=300s
                        """
                    }
                }
            }
        }
        
        stage('Run Smoke Tests') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    echo "Running smoke tests on ${params.DEPLOYMENT_TYPE} environment..."
                    withKubeConfig([credentialsId: "${KUBECONFIG_CREDENTIALS}"]) {
                        sh """
                            # Get pod name
                            POD_NAME=\$(kubectl get pods -n ${NAMESPACE} -l version=${params.DEPLOYMENT_TYPE} -o jsonpath='{.items[0].metadata.name}')
                            
                            # Check if pod is running
                            kubectl wait --for=condition=ready pod/\$POD_NAME -n ${NAMESPACE} --timeout=120s
                            
                            # Run health check
                            kubectl exec \$POD_NAME -n ${NAMESPACE} -- curl -f http://localhost:3000/health || exit 1
                        """
                    }
                }
            }
        }
        
        stage('Switch Traffic') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    echo "Switching traffic to ${params.DEPLOYMENT_TYPE} environment..."
                    
                    // Get user approval before switching traffic
                    input message: "Switch traffic to ${params.DEPLOYMENT_TYPE}?", ok: 'Deploy'
                    
                    withKubeConfig([credentialsId: "${KUBECONFIG_CREDENTIALS}"]) {
                        sh """
                            # Switch service selector to new version
                            kubectl patch service app-service -n ${NAMESPACE} -p '{"spec":{"selector":{"version":"${params.DEPLOYMENT_TYPE}"}}}'
                            
                            # Scale down the old environment
                            OLD_ENV=\$([ "${params.DEPLOYMENT_TYPE}" == "green" ] && echo "blue" || echo "green")
                            kubectl scale deployment myapp-\$OLD_ENV -n ${NAMESPACE} --replicas=1
                        """
                    }
                    
                    echo "Traffic successfully switched to ${params.DEPLOYMENT_TYPE}!"
                }
            }
        }
        
        stage('Rollback') {
            when {
                expression { params.ACTION == 'rollback' }
            }
            steps {
                script {
                    def rollbackEnv = params.DEPLOYMENT_TYPE == 'green' ? 'blue' : 'green'
                    echo "Rolling back to ${rollbackEnv} environment..."
                    
                    withKubeConfig([credentialsId: "${KUBECONFIG_CREDENTIALS}"]) {
                        sh """
                            # Scale up the rollback environment
                            kubectl scale deployment myapp-${rollbackEnv} -n ${NAMESPACE} --replicas=3
                            kubectl rollout status deployment/myapp-${rollbackEnv} -n ${NAMESPACE} --timeout=300s
                            
                            # Switch traffic back
                            kubectl patch service app-service -n ${NAMESPACE} -p '{"spec":{"selector":{"version":"${rollbackEnv}"}}}'
                            
                            # Scale down current environment
                            kubectl scale deployment myapp-${params.DEPLOYMENT_TYPE} -n ${NAMESPACE} --replicas=0
                        """
                    }
                    
                    echo "Successfully rolled back to ${rollbackEnv}!"
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
            // Add notifications (Slack, email, etc.)
        }
        failure {
            echo 'Pipeline failed!'
            // Add notifications for failures
        }
        always {
            cleanWs()
        }
    }
}
```

---

## **Step 6: Implementation Steps**

### **Prerequisites:**

1. **Jenkins Setup:**
   - Install Jenkins with Docker and Kubernetes plugins
   - Install required plugins: Docker Pipeline, Kubernetes CLI, Pipeline

2. **Add Jenkins Credentials:**
```
   - Docker Hub credentials (ID: docker-hub-credentials)
   - Kubeconfig file (ID: kubeconfig-credentials)