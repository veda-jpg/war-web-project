pipeline {
    agent any

    environment {
        TOMCAT_SERVER       = "54.198.195.99:8080"
        TOMCAT_USER         = "ubuntu"
        TOMCAT_CONTAINER    = "tomcat9"

        NEXUS_URL           = "http://3.227.244.28:8081"
        NEXUS_REPOSITORY    = "maven-releases1"
        NEXUS_CREDENTIAL_ID = "nexus_creds"

        SSH_KEY_PATH        = "/var/lib/jenkins/.ssh/jenkins_key"

        SONAR_HOST_URL      = "http://54.198.195.99:9000"
        SONAR_CREDENTIAL_ID = "sonar_creds"
    }

    tools {
        maven "maven3"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'master', url: "https://github.com/veda-jpg/war-web-project.git"
            }
        }

        stage('Build WAR') {
            steps {
                sh "mvn clean package -DskipTests"
                archiveArtifacts artifacts: 'target/*.war'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('Sonar') {
                    withCredentials([string(credentialsId: SONAR_CREDENTIAL_ID, variable: 'SONAR_TOKEN')]) {
                        sh """
                        mvn sonar:sonar \
                            -Dsonar.projectKey=wwp \
                            -Dsonar.host.url=${SONAR_HOST_URL} \
                            -Dsonar.login=${SONAR_TOKEN} \
                            -Dsonar.java.binaries=target/classes
                        """
                    }
                }
            }
        }

        stage('Extract Version') {
            steps {
                script {
                    env.ART_VERSION = sh(
                        script: "mvn help:evaluate -Dexpression=project.version -q -DforceStdout",
                        returnStdout: true
                    ).trim()
                    echo "Version = ${ART_VERSION}"
                }
            }
        }

        stage('Publish to Nexus') {
            steps {
                script {
                    def warFile = sh(script: 'ls target/*.war | head -1', returnStdout: true).trim()

                    nexusArtifactUploader(
                        nexusVersion: "nexus3",
                        protocol: "http",
                        nexusUrl: NEXUS_URL,
                        groupId: "koddas.web.war",
                        artifactId: "wwp",
                        version: ART_VERSION,
                        repository: NEXUS_REPOSITORY,
                        credentialsId: NEXUS_CREDENTIAL_ID,
                        artifacts: [[file: "${warFile}", type: "war"]]
                    )
                }
            }
        }

        stage('Deploy to Docker Tomcat') {
            steps {
                script {
                    def warFile = sh(script: 'ls target/*.war | head -1', returnStdout: true).trim()

                    sh """
                    # Send the WAR to EC2
                    scp -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${warFile} ${TOMCAT_USER}@${TOMCAT_SERVER}:/tmp/app.war

                    # Deploy inside Docker Tomcat container
                    ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${TOMCAT_USER}@${TOMCAT_SERVER} '
                        docker cp /tmp/app.war ${TOMCAT_CONTAINER}:/usr/local/tomcat/webapps/ &&
                        docker restart ${TOMCAT_CONTAINER}
                    '
                    """
                }
            }
        }

        stage('Display URLs') {
            steps {
                echo "🌐 App URL:     http://${TOMCAT_SERVER}:8080/wwp/"
                echo "📦 Nexus URL:   ${NEXUS_URL}/repository/${NEXUS_REPOSITORY}/koddas/web/war/wwp/${ART_VERSION}/wwp-${ART_VERSION}.war"
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully! Access your app at http://${TOMCAT_SERVER}:8080/wwp/"
        }
        failure {
            echo "❌ Pipeline failed. Check Jenkins logs for details."
        }
    }
}
