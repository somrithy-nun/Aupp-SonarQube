pipeline {
    agent any

    environment {
        SONAR_HOST_URL = 'https://sonar.gravastar.store'
        SONAR_PROJECT  = 'express-app'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh """
                        npx sonar-scanner \
                          -Dsonar.projectKey=${SONAR_PROJECT} \
                          -Dsonar.sources=. \
                          -Dsonar.exclusions=node_modules/**,.git/** \
                          -Dsonar.host.url=${SONAR_HOST_URL} \
                          -Dsonar.login=\$SONAR_TOKEN
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }

    post {
        success {
            echo 'SonarQube scan passed quality gate ✓'
        }
        failure {
            echo 'Pipeline failed — check SonarQube dashboard for details'
        }
    }
}