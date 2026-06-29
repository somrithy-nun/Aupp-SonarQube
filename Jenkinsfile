pipeline {
    agent any

    environment {
        SONAR_HOST_URL  = 'https://sonar.gravastar.store'
        SONAR_PROJECT   = 'express-app'
    }

    tools {
        nodejs 'NodeJS-18'   // must match the name in Jenkins > Global Tool Config
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

        stage('Test & Coverage') {
            steps {
                sh 'npm test -- --coverage --coverageReporters=lcov'
            }
            post {
                always {
                    junit 'test-results/**/*.xml'           // optional, if you emit JUnit XML
                    publishHTML(target: [
                        reportDir: 'coverage/lcov-report',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {            // must match the name in Jenkins > Configure System
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
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                sh 'echo "Add your deploy script here"'
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed — check SonarQube report or test output'
        }
        success {
            echo 'Pipeline passed quality gate ✓'
        }
    }
}