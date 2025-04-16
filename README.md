# DevOps-Project-Depi
Repo for Devops project

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

////////////////////////////*