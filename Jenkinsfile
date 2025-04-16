pipeline {
    agent any

    environment {
        TERRAFORM_DIR = "terraform/"
        TERRAFORM_VERSION = "1.6.3"
        TERRAFORM_BIN_DIR = "/usr/local/bin"
        PATH = "${env.HOME}/.local/bin:${env.PATH}"
    }

    stages {
        stage("Prep") {
            steps {
                git(
                    url: "https://github.com/ibrahem365/DevOps-Project-Depi.git",
                    branch: "main",
                )
            }
        }

        stage("Install Terraform") {
            steps {
                script {
                    sh '''
                    set -e
                    echo "Installing unzip..."
                    # Use sudo for package installation
                    sudo apt-get update
                    sudo apt-get install -y unzip
                    echo "Installing Terraform 1.6.3..."
                    mkdir -p ~/.local/bin
                    cd /tmp
                    curl -s -O https://releases.hashicorp.com/terraform/1.6.3/terraform_1.6.3_linux_amd64.zip
                    unzip -o terraform_1.6.3_linux_amd64.zip
                    mv terraform ~/.local/bin/terraform
                    export PATH=~/.local/bin:$PATH
                    terraform --version
                '''
                }
            }
        }

        stage("Terraform Init & Apply") {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'jenkins_ssh_key', keyFileVariable: 'SSH_KEY')]) {
                    dir("${TERRAFORM_DIR}") {
                        sh '''
                            terraform init
                            terraform apply -auto-approve -var ssh_key_path=$SSH_KEY
                        '''
                    }
                }
            }
        }

        stage("Install Docker & Prometheus") {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'jenkins_ssh_key', keyFileVariable: 'SSH_KEY')]) {
                    script {
                        def appIp = readFile('terraform/ec2_public_ip.txt').trim()
                        def prometheusIp = readFile('terraform/prometheus_public_ip.txt').trim()

                        sh """
                            echo "==== Installing Docker on App EC2 ===="
                            ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@${appIp} << 'EOF'
                                set -e
                                sudo apt-get update -y
                                sudo apt-get install -y docker.io
                                sudo systemctl enable docker
                                sudo systemctl start docker
                            EOF

                            echo "==== Installing Prometheus on Prometheus EC2 ===="
                            ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@${prometheusIp} << 'EOF'
                                set -e
                                sudo apt-get update -y
                                sudo apt-get install -y prometheus
                                sudo systemctl enable prometheus
                                sudo systemctl start prometheus
                            EOF
                        """
                    }
                }
            }
        }

        stage("Configure Prometheus Targets") {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'jenkins_ssh_key', keyFileVariable: 'SSH_KEY')]) {
                    script {
                        def appIp = readFile('terraform/ec2_public_ip.txt').trim()
                        def prometheusIp = readFile('terraform/prometheus_public_ip.txt').trim()

                        sh """
                            echo "==== Sending prometheus.yml to Prometheus Server ===="
                            scp -i $SSH_KEY -o StrictHostKeyChecking=no prometheus.yml ubuntu@${prometheusIp}:/home/ubuntu/
                            ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@${prometheusIp} '
                                sudo mv /home/ubuntu/prometheus.yml /etc/prometheus/prometheus.yml && \
                                sudo sed -i "s/publicIp/${appIp}/g" /etc/prometheus/prometheus.yml && \
                                sudo systemctl restart prometheus
                            '
                        """
                    }
                }
            }
        }

        stage("Build Docker Image") {
            steps {
                withCredentials([usernamePassword(credentialsId:"docker", usernameVariable:"USER", passwordVariable:"PASS")]) {
                    sh '''
                        docker build . -t ${USER}/todo-app:v1.${BUILD_NUMBER}
                        docker login -u ${USER} -p ${PASS}
                        docker push ${USER}/todo-app:v1.${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage("Test Docker Image") {
            steps {
                withCredentials([usernamePassword(credentialsId:"docker", usernameVariable:"USER", passwordVariable:"PASS")]) {
                    sh '''
                        docker run --rm ${USER}/todo-app:v1.${BUILD_NUMBER} pytest /app
                    '''
                }
            }
        }

        stage("Deploy to EC2") {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'jenkins_ssh_key', keyFileVariable: 'SSH_KEY'),
                    usernamePassword(credentialsId:"docker", usernameVariable:"USER", passwordVariable:"PASS")
                ]) {
                    script {
                        def appIp = readFile('terraform/ec2_public_ip.txt').trim()

                        sh """
                            ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@${appIp} '
                                docker ps -aq | grep -v \$(docker ps -aqf "name=cadvisor") | xargs -r docker rm -f || true && \
                                docker run -d --name todo-app -p 3000:3000 ${USER}/todo-app:v1.${BUILD_NUMBER}
                            '
                        """
                    }
                }
            }
        }
    }
}