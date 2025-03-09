resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-key"
  public_key = var.jenkins_public_key
}

resource "aws_instance" "linux_docker" {
  ami                   = "ami-08c40ec9ead489470"
  instance_type         = "t2.micro"
  key_name              = aws_key_pair.jenkins_key.key_name

  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker ubuntu
  EOF

  tags = {
    Name = "LinuxDockerInstance"
  }
}
