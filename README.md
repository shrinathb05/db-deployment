# db-deployment
this repository is related to the database automation deployment
Below is a complete step-by-step blueprint to build a reusable Jenkins pipeline for database deployments (MySQL or any DB) using:

Server 1: Jenkins Master

Server 2: Jenkins Agent (Worker) – runs all deployment jobs

Server 3: MySQL Database Server

GitHub: Stores SQL scripts and tags

The pipeline will:

✔ Take Git tag as input
✔ Execute backup scripts first
✔ Execute SQL scripts sequentially
✔ Stop execution if any script fails
✔ Generate logs for backup + execution
✔ Send email notification with logs
✔ Be reusable for any DB deployment

1. Architecture Overview

Developer
   |
   | Push SQL scripts + Tag
   v
GitHub Repository
   |
   v
Jenkins Master
   |
   | (triggers pipeline)
   v
Jenkins Agent (Worker Node)
   |
   | SSH / MySQL Client
   v
MySQL DB Server

The agent executes scripts directly on the DB server.

2. Prerequisites

Minimum recommended:

Server	RAM	CPU
Jenkins Master	4GB	2 CPU
Agent Node	    4GB	2 CPU
MySQL Server	4GB	2 CPU

3. Setup Server 1 – Jenkins Master
Step 1 Install Java

sudo apt update
sudo apt install openjdk-17-jdk -y
java -version

Step 2 Install Jenkins from online site

Step 3 Open Jenkins UI
    http://<jenkins-ip>:8080
Get password
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword

4. Install Required Jenkins Plugins
    Manage Jenkins → Plugin Manager
    Git
    Pipeline
    Pipeline Stage View
    SSH Agent
    Email Extension
    Credentials Binding
    Blue Ocean (optional)
    Git Parameter (for tag selection)

5. Setup Server 2 – Jenkins Agent Node
    All DB scripts will run here.
    Step1 install java
        sudo apt update
        sudo apt install openjdk-17-jdk -y

    Step 2 Install MySQL Client
    Agent must connect to DB server.
        sudo apt install mysql-client -y
        mysql --version

6. Connect Jenkins Agent to Master
    Manage Jenkins
    → Manage Nodes
    → New Node    

    Name: db-agent
    Type: Permanent Agent
    Configuration:
        Remote root directory: /home/ubuntu
        Labels: db-agent
        Launch method:  Launch agent via SSH
        Add credentials:    SSH username/password or SSH key
        Save.   Jenkins will connect automatically.

7. Setup Server 3 – MySQL DB Server 
    Install MySQL
    sudo apt update
    sudo apt install mysql-server -y

    Create Deployment User
    Login:  sudo mysql
    Create user:-
        CREATE USER 'release'@'10.181.63.246' IDENTIFIED BY 'release@123';
        GRANT ALL PRIVILEGES ON *.* TO 'release'@'10.181.63.246';
        FLUSH PRIVILEGES;


        CREATE USER IF NOT EXISTS 'ubuntu'@'10.181.63.246' IDENTIFIED BY 'shrinath@123';
        GRANT ALL PRIVILEGES ON jenkins.* TO 'ubuntu'@'10.181.63.246';
        FLUSH PRIVILEGES;

    Allow Remote Connections
    Edit config:
        sudo vim /etc/mysql/mysql.conf.d/mysqld.cnf
    Change: 
        bind-address = 0.0.0.0
    Restart
        sudo systemctl restart mysql

8. Check on the agent server the user is accesible the mysql or not
    mysql -h agent_ip -u user -ppassword or mysql -h agent_ip -u user -p (ask for for password enter the password)

9. Jenkins Credentials
    Go to:
    Manage Jenkins  → Credentials  →   select the username with password option.
    Add:    MySQL Credentials
    ID: mysql-creds
    username: user
    password: ********

10. Github Credentials
    Go to:
    Manage Jenkins  → Credentials  →   select the secret text
    ID:   github_token
    secret text:    add generated token from github
    