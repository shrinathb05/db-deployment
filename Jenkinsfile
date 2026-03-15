pipeline {
    agent {label 'db-agent'}

    parameters {
        string(name: 'TAG_NAME', description: 'Git Tag to deploy')
        choice(name: 'DB_HOST', choices: ['54.226.206.161','10.10.10.20','10.10.10.30'], description: 'Select Database Server')
        choice(name: 'DATABASE_NAME', choices: ['jenkins','devdb','testdb','proddb'], description: 'Select Database')
        string(name: 'BACKUP_SCRIPT', description: 'Backup SQL filename (example: backup.sql)')
    }

    environment {
        WORK_DIR = "/home/jenkins/var/work/mysql"
        GIT_REPO = "https://github.com/shrinathb05/db-deployment.git"
    }


    stages {
        stage('Clean and prepare workspace') {
            steps {
                echo "Cleaning workspace: ${WORK_DIR}"
                sh """
                    mkdir -p "${WORK_DIR}"
                    rm -rf "${WORK_DIR}/*"
                    echo "Workspace cleaned and ready."
                    ls -l ${WORK_DIR}
                """
            }
        }

        stage ('Checkout Git Tag') {
            steps {
                dir("${WORK_DIR}") {
                    echo "Checking out tag: ${params.TAG_NAME}"

                    checkout([$class: 'GitSCM',
                        branches: [[name: "refs/tags/${params.TAG_NAME}"]],
                        userRemoteConfigs: [[url: "${env.GIT_REPO}"]]
                    ])

                    echo "Files in workspace after checkout:"
                    sh "ls -l ${WORK_DIR}"
                }
            }
        }

        stage('Execute Backup Script') {
            steps {
                dir("${WORK_DIR}") {
                    withCredentials([usernamePassword(
                        credentialsId: 'mysql-creds',
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASS'
                    )]) {
                        sh """
                            set -e

                            echo "===== BACKUP START =====" > backup.log
                            echo "Files in workspace:" >> backup.log
                            ls -l >> backup.log

                            if [ ! -f "${params.BACKUP_SCRIPT}" ]; then
                                echo "Backup script ${params.BACKUP_SCRIPT} not found!" >> backup.log
                                exit 1
                            fi

                            echo "Creating temporary my.cnf for secure connection..." >> backup.log

                            cat > ~/.my.cnf <<EOF
                                [client]
                                user=\$DB_USER
                                password=\$DB_PASS
                                host=${params.DB_HOST}
                                database=${params.DATABASE_NAME}
                                EOF

                            chmod 600 ~/.my.cnf

                            echo "Running backup script ${params.BACKUP_SCRIPT}" >> backup.log
                            mysql < ${params.BACKUP_SCRIPT} >> backup.log 2>&1

                            echo "Backup completed successfully" >> backup.log

                            echo "Removing temporary my.cnf" >> backup.log
                            rm -f ~/.my.cnf
                        """
                    }
                }
            }
        }

    }

    post {
        success {
            echo "Step 1 completed successfully. Workspace is ready."
        }
        failure {
            echo "Step 1 failed. Check workspace permissions or paths."
        }
    }
}