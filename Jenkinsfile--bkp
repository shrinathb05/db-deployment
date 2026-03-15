pipeline {
    agent { label 'db-agent' }

    parameters {
        string(name: 'TAG_NAME', defaultValue: '', description: 'Git Tag')
        string(name: 'DATABASE_NAME', defaultValue: '', description: 'Database')
        string(name: 'DB_HOST', defaultValue: '', description: 'DB Server IP')
        text(name: 'SCRIPT_SEQUENCE', defaultValue: '1.sql\n2.sql\n3.sql', description: 'Script execution order')
    }

    environment {
        GIT_REPO = "https://github.com/shrinathb05/db-deployment.git"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: "refs/tags/${params.TAG_NAME}"]],
                    userRemoteConfigs: [[url: "${env.GIT_REPO}"]]
                ])
            }
        }

        stage('Backup Database') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'mysql-creds', usernameVariable: 'DB_USER', passwordVariable: 'DB_PASS')]) {
                    sh """
                        chmod +x backup/backup.sh
                        ./backup/backup.sh ${params.DB_HOST} \$DB_USER \$DB_PASS ${params.DATABASE_NAME} > backup.log
                    """
                }
            }
        }

        stage('Execute SQL Scripts') {
            steps {
                    withCredentials([usernamePassword(credentialsId: 'mysql-creds', usernameVariable: 'DB_USER', passwordVariable: 'DB_PASS')]) {
                    sh '''
                        #!/bin/bash
                        echo "Starting SQL Execution" > execution.log
                        echo "${SCRIPT_SEQUENCE}" > seq.txt
                        while read file; do
                            echo "Running $file" >> execution.log
                            mysql -h ${DB_HOST} -u $DB_USER -p$DB_PASS ${DATABASE_NAME} < scripts/$file >> execution.log 2>&1
                            if [ $? -ne 0 ]; then
                                echo "FAILED at $file" >> execution.log
                                exit 1
                            fi
                        done < seq.txt
                    '''
                }
            }
        }
    }

    post {
        success {
            emailext(
                subject: "DB Deployment Success",
                body: "Deployment completed successfully.",
                attachmentsPattern: "*.log",
                to: "team@company.com"
            )
        }
        failure {
            emailext(
                subject: "DB Deployment Failed",
                body: "Deployment failed. Check logs.",
                attachmentsPattern: "*.log",
                to: "team@company.com"
            )
        }
    }
}
