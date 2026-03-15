pipeline {

    agent {label 'db-agent'}

    parameters {
        string(name: 'TAG_NAME', description: 'Git Tag to deploy')

        choice(
            name: 'DB_HOST',
            choices: ['54.157.245.234','10.10.10.20','10.10.10.30'],
            description: 'Select Database Server'
        )

        choice(
            name: 'DATABASE_NAME',
            choices: ['jenkins','devdb','testdb','proddb'],
            description: 'Select Database'
        )

        string(
            name: 'BACKUP_SCRIPT',
            description: 'Backup SQL filename (example: backup.sql)'
        )

        // text(
        //     name: 'EXECUTION_SCRIPTS',
        //     description: 'Execution scripts in order (example:\n1.sql\n2.sql\n3.sql)'
        // )
    }

     environment {
        GIT_REPO = "https://github.com/shrinathb05/db-deployment.git"
        WORK_DIR = "/home/jenkins/var/work/mysql"
    }

    stages {

        stage('Clean Working Directory') {
            steps {
                sh """
                mkdir -p ${WORK_DIR}
                rm -rf ${WORK_DIR}/*
                """
            }
        }

        stage('Checkout Tag') {
            steps {
                dir("${WORK_DIR}") {
                    checkout([$class: 'GitSCM',
                        branches: [[name: "refs/tags/${params.TAG_NAME}"]],
                        userRemoteConfigs: [[url: "${env.GIT_REPO}"]]
                    ])
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

                        echo "Running backup script ${params.BACKUP_SCRIPT}" >> backup.log

                        ./run_mysql.sh ${params.DB_HOST} \$DB_USER \$DB_PASS ${params.DATABASE_NAME} ${params.BACKUP_SCRIPT} >> backup.log 2>&1

                        echo "Backup completed successfully" >> backup.log
                        """
                    }
                }
            }
        }
    }
}