pipeline {
    agent any

    environment {
        SONAR_HOST_URL  = 'https://sonar.gravastar.store'
        SONAR_PROJECT   = 'express-app'
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