pipeline {
    agent any

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
        choice(name: 'action', choices: ['apply', 'destroy'], description: 'Select the action to perform')
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION    = 'us-east-1'
        TERRAFORM_VERSION = "1.11.3"
        TERRAFORM_BIN_DIR = "${WORKSPACE}/terraform-bin"
        TERRAFORM_DIR = "terraform/"
        DOCKER_IMAGE = 'flask-todo-app'
        
    }
    

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/ibrahem365/DevOps-Project-Depi.git'
            }
        }
        stage('Install Terraform') {
            steps {
                script {
                    sh '''
                        set -e

                        echo "Creating local bin directory..."
                        mkdir -p ${TERRAFORM_BIN_DIR}
                        cd /tmp

                        echo "Downloading Terraform ${TERRAFORM_VERSION}..."
                        curl -s -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

                        echo "Unzipping..."
                        unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip

                        echo "Moving Terraform binary to local bin dir..."
                        mv terraform ${TERRAFORM_BIN_DIR}/terraform

                        echo "Cleaning up..."
                        rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                    '''
                }
            }
        }
        stage('Terraform Init') {
            steps {
                withEnv(["PATH=${env.TERRAFORM_BIN_DIR}:/usr/bin:/bin"]) {
                    dir("${TERRAFORM_DIR}") {
                        sh '''
                          terraform version
                          terraform init
                        '''
                    }    
                }
            }
        }
       stage('Plan') {
    steps {
        withEnv(["PATH=${TERRAFORM_BIN_DIR}:${env.PATH}"]) {
            dir("${TERRAFORM_DIR}") {
                withCredentials([sshUserPrivateKey(credentialsId: 'jenkins_ssh_key', keyFileVariable: 'SSH_KEY')]) {
                    sh '''
                        terraform plan -out=tfplan -var="ssh_key_path=$SSH_KEY"
                        terraform show -no-color tfplan > tfplan.txt
                    '''
                }
            }
        }
    }
}

        stage('Apply / Destroy') {
            steps {
                withEnv(["PATH=${TERRAFORM_BIN_DIR}:${env.PATH}"]) {
                    dir("${TERRAFORM_DIR}") { 
                        script {
                            if (params.action == 'apply') {
                                if (!params.autoApprove) {
                                 def plan = readFile 'tfplan.txt'
                                 input message: "Do you want to apply the plan?",
                                 parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                                }
              
                            sh 'terraform ${action} -input=false tfplan'
                            } else if (params.action == 'destroy') {
                                sh 'terraform ${action} --auto-approve'
                            } else {
                                error "Invalid action selected. Please choose either 'apply' or 'destroy'."
                            }
                        }
                    }
                }
            }
        }
        stage('Run Ansible Playbook To Configure The Deployment and monitoring Environment') {
            steps {
                // Pass the SSH key and publicIP to Ansible 
                    sh """
                        echo "[todoApp]" > ansible/inventory.ini
                        cat Terraform/ec2_public_ip.txt >> ansible/inventory.ini
                        echo " ansible_user=ubuntu" >> ansible/inventory.ini

                        sleep 30
                    """
                    withCredentials([sshUserPrivateKey(credentialsId: 'jenkins_ssh_key', keyFileVariable: 'SSH_KEY')]) {
                    sh 'ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@ec2-35-154-187-90.ap-south-1.compute.amazonaws.com> "hostname"'

                    withEnv(["ANSIBLE_HOST_KEY_CHECKING=false"]){
                        ansiblePlaybook(
                            playbook: "${ANSIBLE_PLAYBOOK}", 
                            inventory: 'ansible/inventory.ini', 
                            extras: "--private-key=$SSH_KEY"
                        )
                    }
                }
            }
        }
        stage("adding scraping targets to prometheus") {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'jenkins_ssh_key', keyFileVariable: 'SSH_KEY')]) {
                    script {
                        def prometheusIp = readFile('terraform/prometheus_public_ip.txt').trim()
                        def publicIp = readFile('terraform/ec2_public_ip.txt').trim()
                        sh """
                        scp -i $SSH_KEY prometheus.yml ubuntu@${prometheusIp}:/home/ubuntu/
                        ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@${prometheusIp} '
                        sudo mv /home/ubuntu/prometheus.yml /etc/prometheus/prometheus.yml && \
                        sudo sed -i "s/publicIp/${publicIp}/g" /etc/prometheus/prometheus.yml && \
                        sudo systemctl restart prometheus'
                """

                    }
                }
            }
        }
        stage('Build') {
            steps {
                sh '''
                    # Update packages
                    sudo apt-get update

                    # Install required packages
                    sudo apt-get install -y \
                      ca-certificates \
                      curl \
                      gnupg \
                      lsb-release

                    # Add Docker’s official GPG key
                    sudo mkdir -p /etc/apt/keyrings
                    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

                    # Set up the Docker repository
                    echo \
                      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

                    # Install Docker
                    sudo apt-get update
                    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

                    # Verify Docker
                    docker --version
                '''
        
                sh "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ."
                sh "docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest"
                    
                // Save Docker image for potential later deployment
                sh "docker save -o ${DOCKER_IMAGE}.tar ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                    
                // Echo image information
                echo "Built Docker image: ${DOCKER_IMAGE}:${BUILD_NUMBER}"
            }
        }
        stage("Test") {
            steps {
                withCredentials([usernamePassword(credentialsId:"docker",usernameVariable:"USER",passwordVariable:"PASS")]){
                sh 'docker run --rm ${USER}/todo-app:v1.${BUILD_NUMBER} pytest /app'
                }
            }
        }
        stage("Deploy") {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'jenkins_ssh_key', keyFileVariable: 'SSH_KEY')]) {
                    script {
                        def publicIp = readFile('terraform/ec2_public_ip.txt').trim()
                        withCredentials([usernamePassword(credentialsId:"docker",usernameVariable:"USER",passwordVariable:"PASS")]){
                        sh """
                            ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@${publicIp} '
                            docker ps -aq | grep -v \$(docker ps -aqf "name=cadvisor") | xargs -r docker rm -f && \
                            docker run -d --name todo-app -p 3000:3000 ${USER}/todo-app:v1.${BUILD_NUMBER}'
                        """
                        }
                    }
                }
            }
        }
    }
    post {
        success {
            withCredentials([usernamePassword(credentialsId:"docker",usernameVariable:"USER",passwordVariable:"PASS")]){
                slackSend(
                    channel: "depi-project-devops",
                    color: "good",
                    teamDomain: 'devopsproject-a4j4306', tokenCredentialId: 'slack',
                    message: "${env.JOB_NAME} is succeeded. Build no. ${env.BUILD_NUMBER} " + 
                    "(<https://hub.docker.com/repository/docker/${USER}/todo-app/general|Open the image link>)"
                )
            }
        }
        failure {
            slackSend(
                channel: "depi-project-devops",
                color: "danger",
                message: "${env.JOB_NAME} is failed. Build no. ${env.BUILD_NUMBER} URL: ${env.BUILD_URL}",
                teamDomain: 'devopsproject-a4j4306', tokenCredentialId: 'slack'
            )
        }
    }    
}
