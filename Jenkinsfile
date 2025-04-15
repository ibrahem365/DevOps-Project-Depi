pipeline {
    agent any
    
    environment {
        TERRAFORM_DIR = "terraform/"
        ANSIBLE_PLAYBOOK = "ansible/playbook.yml"
    }
    stages {
        stage("Prep") {
            steps {
                git(
                    url: "https://github.com/ibrahem365/DevOps-Project-Depi.git",
                    branch: "main",
                    credentialsId: "GitHub",
                    changelog: true,
                    poll: true
                )
            }
        }
        stage("Terraform init") {
            steps {
                dir("${TERRAFORM_DIR}") {
                    sh 'terraform init'
                }    
            }
        }
        stage('Create ec2 instances using Terraform') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'jenkins_ssh_key', keyFileVariable: 'SSH_KEY')]) {
                    dir("${TERRAFORM_DIR}") {
                        // Apply Terraform and pass the private key to the instance creation process
                        sh """
                        terraform apply -auto-approve -var ssh_key_path=$SSH_KEY
                        """
                    }
                }
            }
        }
        stage('Run Ansible Playbook To Configure The Deployment and monitoring Environment') {
            steps {
                // Pass the SSH key and publicIP to Ansible 
                    sh """
                        echo "[todoApp]" > ansible/inventory.ini
                        cat terraform/ec2_public_ip.txt >> ansible/inventory.ini
                        echo " ansible_user=ubuntu" >> ansible/inventory.ini

                        echo "\n[prometheus]" >> ansible/inventory.ini
                        cat terraform/prometheus_public_ip.txt >> ansible/inventory.ini
                        echo " ansible_user=ubuntu" >> ansible/inventory.ini
                        sleep 30
                    """
                withCredentials([sshUserPrivateKey(credentialsId: 'jenkins_ssh_key', keyFileVariable: 'SSH_KEY')]) {
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
        stage("Build") {
            steps {
                withCredentials([usernamePassword(credentialsId:"docker",usernameVariable:"USER",passwordVariable:"PASS")]){
                sh 'docker build . -t ${USER}/todo-app:v1.${BUILD_NUMBER}'
                sh 'docker login -u ${USER} -p ${PASS}'
                sh 'docker push ${USER}/todo-app:v1.${BUILD_NUMBER}'
                }
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
                    channel: "final-project",
                    color: "good",
                    message: "${env.JOB_NAME} is succeeded. Build no. ${env.BUILD_NUMBER} " + 
                     "(<https://hub.docker.com/repository/docker/${USER}/todo-app/general|Open the image link>)"
                )
            }
        }
        failure {
            withCredentials([sshUserPrivateKey(credentialsId: 'jenkins_ssh_key', keyFileVariable: 'SSH_KEY')]) {
                    dir("${TERRAFORM_DIR}") {
                        // Apply Terraform and pass the private key to the instance creation process
                        sh """
                        terraform destroy -auto-approve -var ssh_key_path=$SSH_KEY
                        """
                    }
                }
            slackSend(
                channel: "final-project",
                color: "danger",
                message: "${env.JOB_NAME} is failed. Build no. ${env.BUILD_NUMBER} URL: ${env.BUILD_URL}"
            )
        }
    }
}
