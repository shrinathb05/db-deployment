pipeline {
    agent {
        label 'agent'
    }
    
    environment {
        GIT_REPO = "https://github.com/shrinathb05/db-deployment.git"
        NOTIFY_EMAIL = "shrinath7028@gmail.com"
    }
    
    stages {
        stage('Clean & Setup') {
            steps {
                cleanWs()
            }
        }
        
        stage('Checkout Tag') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: "refs/tags/${params.TAG_NAME}"]],
                    userRemoteConfigs: [[url: "${env.GIT_REPO}"]]
                ])
                sh "chmod +x run_mysql.sh"
            }
        }
        
        stage('Backup / Pre-Execution') {
            when {
                expression { params.BACKUP_SCRIPT != '' && params.BACKUP_SCRIPT != 'none' }
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'mysql-creds',
                    usernameVariable: 'DB_USER',
                    passwordVariable: 'DB_PASS'
                )]) {
                    script {
                        echo "Checking connectivity to ${params.DB_HOST}:3306..."
                        sh """
                            timeout 5 bash -c 'cat < /dev/null > /dev/tcp/${params.DB_HOST}/3306' || (echo 'ERROR: Port 3306 unreachable'; exit 1)
                        """

                        echo "====== STARTING BACKUP / PRE-EXECUTION ======"
                        // DB_PASS is read directly from environment inside the script for security
                        sh "bash run_mysql.sh '${params.DB_HOST}' '${DB_USER}' '${params.DB_NAME}' '${params.BACKUP_SCRIPT}'"
                    }
                }
            }
        }
        
        stage('Execute Patch') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'mysql-creds',
                    usernameVariable: 'DB_USER',
                    passwordVariable: 'DB_PASS'
                )]) {
                    script {
                        echo "Checking connectivity to ${params.DB_HOST}:3306..."
                        sh """
                            timeout 5 bash -c 'cat < /dev/null > /dev/tcp/${params.DB_HOST}/3306' || (echo 'ERROR: Port 3306 unreachable'; exit 1)
                        """

                        echo "====== EXECUTING DATAFIX / PATCH ======"
                        sh "bash run_mysql.sh '${params.DB_HOST}' '${DB_USER}' '${params.DB_NAME}' '${params.EXECUTE_SCRIPT}'"
                    }
                }
            }
        }
        
        stage('Archive & Cleanup Workspace') {
            steps {
                script {
                    echo "Archiving logs before workspace cleanup..."
                    sh '''
                        mkdir -p ./logs/mysql
                        cp -u /home/ubuntu/logs/mysql/*.log ./logs/mysql/ 2>/dev/null || true
                    '''
                }
                archiveArtifacts artifacts: 'logs/**/*.log', allowEmptyArchive: true
                
                echo "Cleaning workspace after log archive and execution complete..."
                cleanWs()
            }
        }
    }
    
    post {
        always {
            script {
                // If a stage failed before capture, ensure any fresh logs from this build are copied
                sh '''
                    if [ ! -d "./build_logs" ] || [ -z "$(ls -A ./build_logs 2>/dev/null)" ]; then
                        mkdir -p ./build_logs
                        LATEST_LOGS=$(ls -t /home/ubuntu/logs/mysql/*.log 2>/dev/null | head -n 2)
                        for f in $LATEST_LOGS; do
                            cp "$f" ./build_logs/
                        done
                    fi
                '''
            }
            archiveArtifacts artifacts: 'build_logs/*.log', allowEmptyArchive: true
        }

        success {
            emailext (
                to: '$DEFAULT_RECIPIENTS',
                subject: "✅ [SUCCESS] DB Deployment - Build #${env.BUILD_NUMBER} (${params.DB_NAME})",
                body: """
                    <h3>Database Patch Deployment Succeeded</h3>
                    <p><b>Job Name:</b> ${env.JOB_NAME}</p>
                    <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                    <p><b>Target DB Host:</b> ${params.DB_HOST}</p>
                    <p><b>Database:</b> ${params.DB_NAME}</p>
                    <p><b>Backup Script:</b> ${params.BACKUP_SCRIPT ?: 'None'}</p>
                    <p><b>Executed Script:</b> ${params.EXECUTE_SCRIPT}</p>
                    <p><b>Git Tag:</b> ${params.TAG_NAME}</p>
                    <p><b>Console URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <br/>
                    <p><i>Attached: Both latest backup and patch execution logs for this build.</i></p>
                """,
                mimeType: 'text/html',
                attachmentsPattern: 'build_logs/*.log'
            )
            echo "Email sent with current run logs. Cleaning workspace..."
            cleanWs()
        }

        failure {
            emailext (
                to: '$DEFAULT_RECIPIENTS',
                subject: "❌ [FAILED] DB Deployment - Build #${env.BUILD_NUMBER} (${params.DB_NAME})",
                body: """
                    <h3 style="color:red;">Database Patch Deployment Failed</h3>
                    <p><b>Job Name:</b> ${env.JOB_NAME}</p>
                    <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                    <p><b>Target DB Host:</b> ${params.DB_HOST}</p>
                    <p><b>Database:</b> ${params.DB_NAME}</p>
                    <p><b>Backup Script:</b> ${params.BACKUP_SCRIPT ?: 'None'}</p>
                    <p><b>Executed Script:</b> ${params.EXECUTE_SCRIPT}</p>
                    <p><b>Git Tag:</b> ${params.TAG_NAME}</p>
                    <p><b>Console URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <br/>
                    <p><i>Attached: Detailed execution error logs for this build.</i></p>
                """,
                mimeType: 'text/html',
                attachmentsPattern: 'build_logs/*.log'
            )
            echo "Failure email sent with logs. Cleaning workspace..."
            cleanWs()
        }
    }
}