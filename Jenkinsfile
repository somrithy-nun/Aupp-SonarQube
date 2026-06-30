pipeline {
    agent any

    environment {
        SONAR_HOST_URL  = 'https://sonar.gravastar.store'
        SONAR_PROJECT   = 'express-app'
        TRIVY_IMAGE     = 'aquasec/trivy:latest'
        APP_IMAGE       = 'aupp-sonarqube-app:latest'
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
                          -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
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


        // stage('Deploy') {
        //     when {
        //         branch 'main'
        //     }
        //     steps {
        //         sh '''
        //             if [ -n "${EC2_HOST:-}" ] && [ -n "${SSH_KEY:-}" ]; then
        //               sh scripts/task14-deploy-ec2.sh
        //             else
        //               echo "Skipping EC2 deploy. Set EC2_HOST and SSH_KEY to run Task 14."
        //             fi
        //         '''
        //     }
        // }
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
