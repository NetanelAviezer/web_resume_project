# Retrieve all subnets in the default VPC (you must have data "aws_vpc" "default" defined in main.tf)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create a DB subnet group for RDS
resource "aws_db_subnet_group" "default" {
  name       = "default-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "Default DB Subnet Group"
  }
}

# RDS Instance configured for free tier (PostgreSQL) using minimal settings.
# By not specifying a db_subnet_group_name, the default DB subnet group from the default VPC will be used.
resource "aws_db_instance" "default" {
  allocated_storage      = 20               # Free-tier eligible storage size (GiB)
  engine                 = "postgres"
  engine_version         = "15"             
  instance_class         = "db.t3.micro"    
  identifier             = "my-free-tier-db"
  db_name                = "resume_db"
  username               = "neho"
  password               = "!Twork314Nh"  
  parameter_group_name   = "default.postgres15"
  skip_final_snapshot    = true
  publicly_accessible    = true            
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}
