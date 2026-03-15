pipeline {

    agent {label 'db-agent'}

    parameters {
        string(name: 'TAG_NAME', description: 'Git Tag to deploy')

        choice(
            name: 'DB_HOST',
            choices: ['54.226.206.161','10.10.10.20','10.10.10.30'],
            description: 'Select Database Server'
        )

        choice(
            name: 'DB_NAME',
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

                // This command removes Windows line endings from all shell and SQL files
                sh "find . -type f -name '*.sh' -o -name '*.sql' | xargs sed -i 's/\\r\$//'"

                sh "chmod +x run_mysql.sh"
            }
        }
        // stage('Execute Backup Script') {
        //     steps {
        //         dir("${env.WORK_DIR}") {
        //             withCredentials([usernamePassword(
        //                 credentialsId: 'mysql-creds',
        //                 usernameVariable: 'DB_USER',
        //                 passwordVariable: 'DB_PASS'
        //             )]) {
        //                 sh """
        //                 # Stop using '>> backup.log' temporarily so you can see the error
        //                 echo "===== BACKUP START ====="
                        
        //                 if [ ! -f "${params.BACKUP_SCRIPT}" ]; then
        //                     echo "ERROR: ${params.BACKUP_SCRIPT} not found!"
        //                     exit 1
        //                 fi

        //                 # Call the script using bash explicitly
        //                 bash run_mysql.sh \"${params.DB_HOST}\" \"\$DB_USER\" \"\$DB_PASS\" \"${params.DB_NAME}\" \"${params.BACKUP_SCRIPT}\"
        //                 """
        //             }
        //         }
        //     }
        // }
        stage('Execute Backup Script') {
            steps {
                dir("${env.WORK_DIR}") {
                    withCredentials([usernamePassword(
                        credentialsId: 'mysql-creds',
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASS'
                    )]) {
                        sh """
                        set -e
                        echo "===== STARTING DEPLOYMENT ====="
                        
                        # Check if MySQL is even reachable before running the script
                        # This will tell us if it's a network/firewall issue
                        echo "Checking connectivity to ${params.DB_HOST}..."
                        timeout 5 bash -c 'cat < /dev/null > /dev/tcp/${params.DB_HOST}/3306' || (echo "ERROR: Cannot reach Port 3306 on ${params.DB_HOST}"; exit 1)

                        # Run the script without redirecting to a file so we see the error
                        bash run_mysql.sh "${params.DB_HOST}" "\$DB_USER" "\$PASS" "${params.DB_NAME}" "${params.BACKUP_SCRIPT}"
                        """
                    }
                }
            }
        }
    }
}