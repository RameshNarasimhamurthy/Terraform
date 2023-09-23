provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-vpc"
  }
}
resource "aws_subnet" "public_subnet" {
  count             = 2
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = element(["10.0.1.0/24", "10.0.2.0/24"], count.index)
  availability_zone = element(["us-west-1a", "us-west-1c"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnet" {
  count             = 2
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = element(["10.0.3.0/24", "10.0.4.0/24"], count.index)
  availability_zone = element(["us-west-1a", "us-west-1c"], count.index)

  tags = {
    Name = "private-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_kms_key" "my_cmk" {
  description             = "My CMK Key"
  deletion_window_in_days = 7

  tags = {
    Name = "my-cmk"
  }
}

variable "subnet_id" {
  description = "ID of the subnet for EC2 instance"
  default     = "subnet-044aaba122789f493" 
}

variable "cmk_key_id" {
  description = "ID of the KMS key for RDS encryption"
  default     = "arn:aws:kms:us-west-1:284441042484:key/bb926421-f68d-4a06-af71-ea36907106ad"  
}

resource "aws_instance" "my-ec2" {
  ami           = "ami-0f8e81a3da6e2510a"
  instance_type = "t2.micro"
  subnet_id     = var.subnet_id
  key_name      = "terraform"
  ebs_block_device {
    device_name           = "/dev/sda1"
    volume_size           = 30
    encrypted             = true
    kms_key_id            = var.cmk_key_id
  }
 

  tags = {
    Name = "my-ec2"
  }
}

resource "aws_db_instance" "my_rds" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.small"
  username             = "admin"
  password             = "admin123"
  vpc_security_group_ids = ["sg-035d08a3db629a84b"]
 
  tags = {
    Name = "my-rds"
  }

  storage_encrypted = true 
  skip_final_snapshot  = true 

  kms_key_id = var.cmk_key_id
}
