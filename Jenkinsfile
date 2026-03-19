pipeline {
    agent {label 'node1' }
    
    parameters {
        string(name: 'TAG_NAME', defaultValue: 'v0.7', description: 'Git tag to deploy')
        
        choice(
            name: 'DB_HOST',
            choices: ['10.181.63.162', '10.181.63.132', '10.181.63.125'],
            description: 'Select Database Server'
        )
        
        choice(
            name: 'DB_NAME',
            choices: ['jenkins', 'DEV', 'PRE-PROD', 'PROD'],
            description: 'Select Database NAME'
        )
        
        string(
            name: 'BACKUP_SCRIPT',
            defaultValue: '',
            description: 'e.g. backup.sql file'
        )
        text(
            name: 'EXECUTE_SCRIPT',
            defaultValue: '',
            description: 'Provide the sequence of the file for execution'
        )
    }
    
    environment {
        GIT_REPO = "https://github.com/shrinathb05/db-deployment.git"
        WORK_DIR = "/home/ubuntu/var/work/mysql"
    }
    
    stages {
        stage('Clean & Setup') {
            steps {
                sh """
                    mkdir -p "${WORK_DIR}"
                    rm -rf "${WORK_DIR}/*"
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
        
        stage('Backup') {
            steps {
                dir("${WORK_DIR}") {
                    withCredentials([usernamePassword(
                        credentialsId: 'mysql-creds',
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASS'
                    )]) {
                        script {
                            // //1. Check Connectivity
                            echo "Checking connectivity to ${params.DB_HOST}...."
                            sh """
                                timeout 5 bash -c 'cat < /dev/null > /dev/tcp/${params.DB_HOST}/3306' || (echo 'ERROR: Port 3306 unreachable'; exit 1)
                                ls -lrt
                            """

                            echo "====== STARTING BACKUP (Optional) ======"
                            
                            // catchError allows the pipeline to continue even if this block fails
                            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                if (params.BACKUP_SCRIPT == "" || params.BACKUP_SCRIPT == "none") {
                                    echo "No backup name provided. Forcing failure to meet requirement..."
                                    sh "exit 1" // This forces the stage to fail
                                } else {
                                    sh "bash run_postgres.sh ${params.DB_HOST} \$DB_USER \$DB_PASS ${params.DB_NAME} ${params.BACKUP_SCRIPT}"
                                }
                            }
                        }
                    }
                }
            }
        }
        
        stage('Execute') {
            steps {
                dir("$WORK_DIR") {
                    withCredentials([usernamePassword(
                        credentialsId: 'mysql-creds',
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASS'
                    )]) {
                        //1. Check Connectivity
                        echo "Checking connectivity to ${params.DB_HOST}...."
                        sh """
                            timeout 5 bash -c 'cat < /dev/null > /dev/tcp/${params.DB_HOST}/3306' || (echo 'ERROR: Port 3306 unreachable'; exit 1)
                            ls -lrt
                        """
                        // 2. Execute Backup
                        echo "====== STARTING BACKUP ======"
                        sh "bash run_mysql.sh ${params.DB_HOST} \$DB_USER \$DB_PASS ${params.DB_NAME} ${params.EXECUTE_SCRIPT}"
                    }
                }
            }
        }

        stage('Clean Directory After Deployment') {
            steps {
                sh "rm -rf ${WORK_DIR}/*"
            }
        }
    }
}