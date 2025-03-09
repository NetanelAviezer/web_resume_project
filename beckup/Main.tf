provider "aws" {
    region = "us-east-1"
}

# Use the default VPC which usually meets AZ requirements for RDS
data "aws_vpc" "default" {
  default = true
}

# Security group for RDS: allow inbound PostgreSQL traffic from EC2
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow EC2 access to RDS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432            # PostgreSQL default port
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.instance_sg.id]  # Allow EC2 security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS Instance configured for free tier (PostgreSQL) using minimal settings.
# By not specifying a db_subnet_group_name, the default DB subnet group from the default VPC will be used.
resource "aws_db_instance" "default" {
  allocated_storage      = 20               # Free-tier eligible storage size
  engine                 = "postgres"
  engine_version         = "15"             # Use a free-tier supported version
  instance_class         = "db.t3.micro"    # Free-tier eligible instance class
  identifier             = "my-free-tier-db"
  db_name                = "resume_db"
  username               = "neho"
  password               = "!Twork314Nh"  
  parameter_group_name   = "default.postgres15"
  skip_final_snapshot    = true
  publicly_accessible    = true            
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

# Security group for EC2: only allow SSH (no need to reference RDS here)
resource "aws_security_group" "instance_sg" {
  name        = "linux-docker-sg"
  description = "Allow SSH access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH access from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "jenkins_public_key" {
  description = "Public key for the Jenkins deployment key"
  type        = string
}

resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-key"
  public_key = var.jenkins_public_key
}



# EC2 instance to install Docker (using the default VPC)
resource "aws_instance" "linux_docker" {
  ami                    = "ami-08c40ec9ead489470"  # Verify this AMI is correct for your region
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.jenkins_key.key_name
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y docker.io git
    sudo service docker start
    sudo usermod -aG docker ubuntu
  EOF

  tags = {
    Name = "LinuxDockerInstance1"
  }
}

output "db_address" {
  value = aws_db_instance.default.address
}

output "db_username" {
  value = aws_db_instance.default.username
}

output "instance_public_ip" {
  value = aws_instance.linux_docker.public_ip
}

