pipeline {
    agent { label 'db-agent' }

    parameters {
        string(name: 'TAG_NAME', defaultValue: '', description: 'Git Tag to deploy')
        
        choice(
            name: 'DB_HOST',
            choices: ['54.226.206.161', '10.10.10.20', '10.10.10.30'],
            description: 'Select Database Server'
        )

        choice(
            name: 'DB_NAME',
            choices: ['jenkins', 'devdb', 'testdb', 'proddb'],
            description: 'Select Database'
        )

        string(
            name: 'BACKUP_SCRIPT',
            defaultValue: 'backup.sql',
            description: 'Backup SQL filename'
        )

        text(
            name: 'EXECUTION_SEQUENCE',
            defaultValue: 'execute1.sql\nexecute2.sql\nexecute3.sql',
            description: 'Scripts to run in order (one per line)'
        )
    }

    environment {
        GIT_REPO = "https://github.com/shrinathb05/db-deployment.git"
        WORK_DIR = "/home/jenkins/var/work/mysql"
    }

    stages {
        stage('Clean & Setup') {
            steps {
                sh "mkdir -p ${WORK_DIR} && rm -rf ${WORK_DIR}/*"
            }
        }

        stage('Checkout Tag') {
            steps {
                dir("${WORK_DIR}") {
                    checkout([$class: 'GitSCM',
                        branches: [[name: "refs/tags/${params.TAG_NAME}"]],
                        userRemoteConfigs: [[url: "${env.GIT_REPO}"]]
                    ])
                    
                    // Fix Windows line endings and set permissions
                    sh "find . -type f -name '*.sh' -o -name '*.sql' | xargs sed -i 's/\\r\$//'"
                    sh "chmod +x run_mysql.sh"
                }
            }
        }

        stage('Database Deployment') {
            steps {
                dir("${env.WORK_DIR}") {
                    withCredentials([usernamePassword(
                        credentialsId: 'mysql-creds',
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASS'
                    )]) {
                        script {
                            // 1. Check Connectivity
                            echo "Checking connectivity to ${params.DB_HOST}..."
                            sh "timeout 5 bash -c 'cat < /dev/null > /dev/tcp/${params.DB_HOST}/3306' || (echo 'ERROR: Port 3306 unreachable'; exit 1)"

                            // 2. Execute Backup
                            echo "===== STARTING BACKUP ====="
                            sh "bash run_mysql.sh '${params.DB_HOST}' '\$DB_USER' '\$DB_PASS' '${params.DB_NAME}' '${params.BACKUP_SCRIPT}'"

                            // 3. Execute Sequence
                            echo "===== STARTING EXECUTION SEQUENCE ====="
                            def scripts = params.EXECUTION_SEQUENCE.split('\n')
                            for (sqlFile in scripts) {
                                if (sqlFile.trim()) {
                                    echo "Executing: ${sqlFile}"
                                    // Pipeline will terminate here if any script fails
                                    sh "bash run_mysql.sh '${params.DB_HOST}' '\$DB_USER' '\$DB_PASS' '${params.DB_NAME}' '${sqlFile.trim()}'"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            dir("${env.WORK_DIR}") {
                // Archive logs so they appear in Jenkins UI
                archiveArtifacts artifacts: 'logs/*.log', allowEmptyArchive: true
                
                // Email Notification with logs attached
                emailext (
                    to: 'shrinath@example.com', // Replace with your email
                    subject: "DB Deployment ${currentBuild.currentResult}: Tag ${params.TAG_NAME}",
                    body: """Status: ${currentBuild.currentResult}
                             Database: ${params.DB_HOST}
                             Tag: ${params.TAG_NAME}
                             
                             Attached are the execution logs.""",
                    attachmentsPattern: 'logs/*.log'
                )
            }
        }
    }
}