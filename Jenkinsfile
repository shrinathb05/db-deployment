pipeline {
    agent {
        label 'agent'
    }

    parameters {
        string(name: 'TAG_NAME', defaultValue: 'v2.4', description: 'Git Tag to checkout')
        string(name: 'DB_HOST', defaultValue: '10.41.222.183', description: 'Target DB Host IP')
        string(name: 'DB_NAME', defaultValue: 'app_test_db', description: 'Database Name')
        string(name: 'BACKUP_SCRIPT', defaultValue: '', description: 'Pre-patch backup or safety script (optional)')
        text(name: 'EXECUTE_SCRIPTS', defaultValue: '01_create_table.sql\n02_insert_records.sql\n03_update_record.sql\n04_delete_record.sql', description: 'Enter SQL scripts (one per line) in execution order')
    }
    
    environment {
        GIT_REPO = "https://github.com/shrinathb05/db-deployment.git"
    }
    
    stages {
        stage('Clean & Setup') {
            steps {
                cleanWs()
                sh 'mkdir -p ./build_logs'
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
                expression { params.BACKUP_SCRIPT?.trim() != '' && params.BACKUP_SCRIPT?.trim() != 'none' }
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

                        def backupFile = params.BACKUP_SCRIPT.trim()
                        echo "====== STARTING BACKUP: ${backupFile} ======"
                        sh "bash run_mysql.sh '${params.DB_HOST}' '${DB_USER}' '${params.DB_NAME}' '${backupFile}'"
                    }
                }
            }
        }
        
        stage('Execute Patch(es)') {
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

                        // Split multiline input into individual scripts and run sequentially
                        def scriptList = params.EXECUTE_SCRIPTS.tokenize('\n')
                        
                        for (item in scriptList) {
                            def sqlFile = item.trim()
                            if (sqlFile && !sqlFile.startsWith("#")) {
                                echo "====== EXECUTING: ${sqlFile} ======"
                                sh "bash run_mysql.sh '${params.DB_HOST}' '${DB_USER}' '${params.DB_NAME}' '${sqlFile}'"
                            }
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
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
                    <p><b>Executed Scripts:</b><pre>${params.EXECUTE_SCRIPTS}</pre></p>
                    <p><b>Git Tag:</b> ${params.TAG_NAME}</p>
                    <p><b>Console URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <br/>
                    <p><i>All execution logs generated during this run are attached to this email.</i></p>
                """,
                mimeType: 'text/html',
                attachmentsPattern: 'build_logs/*.log'
            )
            echo "Email sent. Cleaning workspace..."
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
                    <p><b>Executed Scripts:</b><pre>${params.EXECUTE_SCRIPTS}</pre></p>
                    <p><b>Git Tag:</b> ${params.TAG_NAME}</p>
                    <p><b>Console URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <br/>
                    <p><i>Check attached logs for failure details.</i></p>
                """,
                mimeType: 'text/html',
                attachmentsPattern: 'build_logs/*.log'
            )
            echo "Failure email sent. Cleaning workspace..."
            cleanWs()
        }
    }
}