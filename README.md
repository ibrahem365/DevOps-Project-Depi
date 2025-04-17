# Final Project

## 📂 Project Structure Overview

```
.
├── ansible/            # Contains Ansible playbooks & inventory
├── templates/          # Jinja2 templates for Ansible (if used)
├── terraform/          # Infrastructure as Code (Terraform)
│   ├── modules/
│   │   ├── ec2/        # EC2 instance provisioning
│   │   ├── sg/         # Security Group configurations
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── output.tf
├── .dockerignore       # Ignore files for Docker builds
├── .gitignore          # Ignore files for Git
├── Dockerfile          # Dockerfile to containerize the Flask app
├── Jenkinsfile         # Jenkins pipeline for CI/CD
├── README.md           # Project documentation
├── app.py              # Flask application logic
├── prometheus.yml      # Prometheus configuration for monitoring
├── requirements.txt    # Python dependencies
├── test_app.py         # Pytest test cases for the Flask app
└── wsgi.py             # WSGI entry point for Gunicorn
```

## 🛠 How Everything Works

### **CI/CD (Jenkinsfile)**

- Automates testing, building, and deployment of the app.
- Uses Terraform to provision EC2 instances.
- Uses Ansible to configure and deploy the application.
- Sends Slack notifications on success/failure.

### **Infrastructure (Terraform)**

- Provisions EC2 instances & security groups.
- Outputs instance IPs for Ansible to use.

### **Configuration Management (Ansible)**

- Installs dependencies and deploys the Flask app on EC2.
- Sets up Prometheus monitoring.

### **Application (Flask + Gunicorn)**

- Simple ToDo application with Prometheus metrics.
- Packaged in a Docker container.

### **Monitoring (Prometheus + Grafana)**

- Prometheus config (`prometheus.yml`) scrapes metrics.
- Can be extended with Grafana for visualization.

## ✅ Setup & Deployment

### **Prerequisites**

- Docker
- Terraform
- Ansible
- Jenkins
- AWS CLI configured with access keys

### **1️⃣ Clone the Repository**

```sh
git clone https://github.com/mhosnyamer/DEPI-ToDoList.git
cd DEPI-ToDoList
```

### **2️⃣ Initialize Terraform**

```sh
cd terraform
terraform init
```

### **3️⃣ Apply Terraform Configuration**

```sh
terraform apply -auto-approve
```

### **4️⃣ Configure Ansible & Deploy Application**

```sh
cd ansible
ansible-playbook -i inventory.ini playbook.yml --private-key <your-key.pem>
```

### **5️⃣ Run Jenkins Pipeline**

- Configure Jenkins with the provided `Jenkinsfile`.
- Ensure all credentials (GitHub, Docker, AWS, SSH) are added.
- Run the pipeline to deploy automatically.

### **6️⃣ Verify Monitoring**

- Access Prometheus at `http://<prometheus-server-ip>:9090`
- Add scraping targets in `prometheus.yml`.

