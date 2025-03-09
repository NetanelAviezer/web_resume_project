# Flask Resume Project

## Overview

The Flask Resume Project is a containerized Flask application deployed on AWS that showcases a modern DevOps workflow. This project demonstrates the integration of Docker, Jenkins, Terraform, and Ansible to provision infrastructure and deploy web applications in a repeatable, automated way. By leveraging AWS services (EC2 and RDS), the project provides a comprehensive example of infrastructure-as-code and CI/CD best practices.

The pipeline handles the entire deployment process, from provisioning cloud resources to configuring servers and deploying the application. It includes application verification to ensure successful deployment and implements security best practices for credential management.

## Key Features

- **Containerized Application**: Flask application packaged with Docker for consistent deployment
- **Infrastructure as Code**: AWS resources provisioned using Terraform
- **Configuration Management**: Server configuration automated with Ansible
- **CI/CD Pipeline**: Automated deployment with Jenkins
- **Database Integration**: AWS RDS PostgreSQL database for persistent storage
- **Application Verification**: Automated health checks to ensure successful deployment
- **Secure Credential Management**: All sensitive information stored securely in Jenkins
- **Robust Error Handling**: Retry mechanisms and detailed logging for troubleshooting

## Prerequisites

Before starting, ensure you have the following installed and configured:

- **Jenkins** with the following plugins installed:
  - Pipeline plugin
  - Docker plugin
  - Credentials Binding plugin
  - SSH Agent plugin
- **Jenkins Credentials**:
  - `aws-access-key-id`: AWS access key ID
  - `aws-secret-access-key`: AWS secret access key
  - `jenkins-public-key`: EC2 SSH public key
  - `jenkins-ssh-private-key`: SSH private key for EC2 access
  - `db-username`: Database username
  - `db-password`: Database password
- **Docker**: For building and running container images
- **Terraform**: For provisioning AWS infrastructure (EC2, RDS, and security groups)
- **Ansible**: For configuring the application on the provisioned AWS environment
- **AWS CLI**: For AWS interactions during the deployment process
- **Python**: For running the Flask application locally

## Project Structure

### DB Folder
- `init.sql`: 
  - Contains SQL commands used to configure and initialize the database schema for local deployment
  - Sets up necessary tables and configurations required by the application
  - Note: For containerized deployment, a separate Docker file for Postgres is available in another folder

### Web Folder
- `Dockerfile`:
  - Builds a Docker image using a Python Slim base image
  - Installs the required dependencies from the requirements file
  
- `models.py`:
  - Defines data models for the application
  - Includes models for likes and comments
  
- `db.py`:
  - Configures the database connection
  - In this setup, the application uses AWS RDS
  - Connection details are defined via Jenkins environment variables
  
- `app.py`:
  - The main Flask application file
  - Sets up routes, integrates models, and serves the application

### Jenkins Folder
- `Jenkins-tera_ansi` (Pipeline File):
  - A Jenkins pipeline that automates the deployment process
  - Provides parameterized builds for flexible deployment options
  - Securely handles AWS and database credentials

  #### Pipeline Stages:
  1. **Checkout**:
     - Clones the repository (using the master branch)
     - Lists YAML and Terraform files for debugging

  2. **Pre-cleanup**:
     - Deletes any existing EC2 key pair (jenkins-key) using an AWS CLI container
     - Ensures a clean deployment environment

  3. **Terraform Init & Plan**:
     - **Terraform Init**: Initializes Terraform in the terraform folder
     - **Plan**: Generates a Terraform plan using a Jenkins-provided public key credential
     - Saves the output for review

  4. **Apply / Destroy**:
     - Depending on the selected action:
       - **Apply**: Optionally prompts for manual approval before applying the Terraform plan
       - **Destroy**: Automatically destroys the infrastructure if selected

  5. **Ansible Deploy**:
     - When applying changes, this stage:
       - Retrieves outputs from Terraform (such as the EC2 public IP and RDS endpoint)
       - Sets them as environment variables
       - Uses Jenkins credentials to securely fetch SSH keys and RDS connection details
       - Generates an Ansible inventory file dynamically from Terraform outputs
       - Runs the Ansible playbook (ansible/deploy.yml) to deploy the application
       - Passes database connection parameters securely from Jenkins credentials

  6. **Post Steps**:
     - Cleans up sensitive files (like SSH keys)
     - Logs the success or failure of the deployment

### Terraform Folder
- Contains scripts that provision the required AWS infrastructure:
  - **EC2 Security Group**:
    - Creates a security group to manage network access for the EC2 instance
  - **RDS Instance**:
    - Provisions an AWS RDS instance that serves as the application's database backend
  - These Terraform scripts ensure consistent and repeatable infrastructure provisioning using infrastructure-as-code principles

### Ansible Folder
- Includes playbooks and configuration files for finalizing the deployment:
  - **deploy.yml** (and other Ansible files):
    - Configures the EC2 instance by installing dependencies and setting up the Flask application
    - Passes critical RDS parameters (endpoint, username, password, database, port, and SSL mode) to ensure proper connectivity and configuration

### Backup Folder
- Stores legacy or previous versions of configuration files and scripts
- Acts as an archive, providing a fallback or reference in case of issues with the current deployment setup

## Deployment Process

### Local Development
1. Clone the repository:
   ```
   git clone https://github.com/NehorayHillel/flask_resume.git
   cd flask_resume
   ```

2. Set up a local database using the `init.sql` script in the DB folder

3. Run the Flask application:
   ```
   cd web
   python app.py
   ```

### AWS Deployment with Jenkins
1. Configure Jenkins with the required credentials listed in the Prerequisites section
2. Install the following software on your Jenkins server:
   - Docker
   - Terraform
   - Ansible
   - AWS CLI (if not using Docker container)
3. Create a new Jenkins pipeline using the `Jenkins-tera_ansi` file
4. Run the pipeline with the following parameters:
   - `action`: Choose between 'apply' to deploy or 'destroy' to tear down
   - `autoApprove`: Set to true to skip manual approval or false to review Terraform plan
5. Monitor the deployment stages in the Jenkins console
6. The pipeline will automatically verify the application is running correctly
7. Once complete, access the application via the EC2 public IP address displayed in the Jenkins logs

## Security Considerations

- All sensitive information (AWS credentials, SSH keys, database credentials) is stored in Jenkins credentials, not hardcoded in scripts
- SSH keys are properly managed and cleaned up after use
- All database connections use SSL for secure data transmission
- AWS resources are provisioned with appropriate security groups
- Temporary credentials and files are deleted in post-build steps
- Multiple layers of credential protection with Jenkins credential binding

## Architecture Diagram

```
┌────────────┐     ┌────────────┐     ┌────────────────┐
│            │     │            │     │                │
│   Jenkins  │────▶│  Terraform │────▶│  AWS EC2       │
│   Server   │     │  Scripts   │     │  (Flask App)   │
│            │     │            │     │                │
└────────────┘     └────────────┘     └────────┬───────┘
                                               │
                        ┌────────────────────┐ │
                        │                    │ │
                        │  AWS RDS           │◀┘
                        │  (PostgreSQL)      │
                        │                    │
                        └────────────────────┘
```

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add some amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

Nehoray Hillel - [your-email@example.com](mailto:your-email@example.com)

Project Link: [https://github.com/NehorayHillel/flask_resume](https://github.com/NehorayHillel/flask_resume)
