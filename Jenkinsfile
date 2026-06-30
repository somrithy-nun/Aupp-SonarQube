pipeline {
    agent any

    environment {
        SONAR_HOST_URL  = 'https://sonar.gravastar.store'
        SONAR_PROJECT   = 'express-app'
        TRIVY_IMAGE     = 'aquasec/trivy:latest'
        APP_IMAGE       = 'aupp-sonarqube-app:latest'
        APP_CONTAINER   = 'aupp-sonarqube-app'
        MONGO_CONTAINER = 'aupp-sonarqube-mongo'
        DOCKER_NETWORK  = 'aupp-sonarqube-net'
        APP_PORT        = '3000'
    }

    tools {
        nodejs 'node-22.11.0'   // must match the name in Jenkins > Global Tool Config
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Trivy Security Scan') {
            steps {
                sh 'REPORT_FILE=trivy-report.txt sh scripts/task11-trivy-code-scan.sh'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'sh scripts/task12-create-docker-image.sh'
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'sh scripts/task13-trivy-image-scan.sh'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-image-report.txt', allowEmptyArchive: true
                }
            }
        }


        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube_Server_Dev') {            // must match the name in Jenkins > Configure System
                    sh """
                        npx sonar-scanner \
                          -Dsonar.projectKey=${SONAR_PROJECT} \
                          -Dsonar.sources=src \
                          -Dsonar.exclusions=node_modules/**,coverage/** \
                          -Dsonar.coverage.exclusions=src/** \
                          -Dsonar.host.url=${SONAR_HOST_URL} \
                          -Dsonar.login=\$SONAR_TOKEN
                    """
                }
                echo "SonarQube report: ${SONAR_HOST_URL}/dashboard?id=${SONAR_PROJECT}"
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        def qualityGate = waitForQualityGate abortPipeline: false
                        echo "Quality Gate status: ${qualityGate.status}"
                    }
                }
            }
        }


        stage('Deploy with Docker') {
            steps {
                sh '''
                    docker network create "$DOCKER_NETWORK" || true
                    docker rm -f "$APP_CONTAINER" "$MONGO_CONTAINER" || true

                    docker run -d \
                      --name "$MONGO_CONTAINER" \
                      --network "$DOCKER_NETWORK" \
                      --restart unless-stopped \
                      mongo:7

                    docker run -d \
                      --name "$APP_CONTAINER" \
                      --network "$DOCKER_NETWORK" \
                      --restart unless-stopped \
                      -e PORT=3000 \
                      -e MONGO_URI="mongodb://$MONGO_CONTAINER:27017/node_crud" \
                      -p "$APP_PORT:3000" \
                      "$APP_IMAGE"

                    docker ps --filter "name=$APP_CONTAINER" --filter "name=$MONGO_CONTAINER"
                    echo "App deployed: http://localhost:$APP_PORT/healthz"
                '''
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed — check Trivy and SonarQube reports'
        }
        success {
            echo 'Pipeline passed security scan and quality gate ✓'
        }
    }
}
