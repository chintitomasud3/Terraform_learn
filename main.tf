terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}



data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "frontend_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.chintito_sg.id]
  
  key_name     = "private_asia_masud"
  associate_public_ip_address = true
   # 👇 USER DATA START
 user_data = <<-EOF
              #!/bin/bash
              echo "<h1>Hello from chintitomasudserver</h1>" > /tmp/masudoutput.txt
              chmod 644 /tmp/masudoutput.txt
              EOF
 user_data_replace_on_change   = false         
  tags = {
    Name = "masud_frontend_server"
  }
}

resource "aws_vpc" "chintito_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "chintito_vpc_terraform"
  }
}

resource "aws_security_group" "chintito_sg" {
 
  name        = "chintito_masud"
  description = "Security Group Created By masudur rahman"
  vpc_id      = aws_vpc.chintito_vpc.id
  #SSh Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Http access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "chintito_sg_terraform"
  }

}



#public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.chintito_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "chintito_subnet_Public_terraform"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.chintito_vpc.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "chintito_subnet_Private_terraform"
  }
}


resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.chintito_vpc.id
  tags = {
    Name = "chintito_igw_terraform"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.chintito_vpc.id
  tags = {
    Name = "chintito_public_rt_terraform"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }
} 

resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}






# data "aws_vpc" "specific" {
#   filter {
#     name   = "tag:Name"
#     values = ["chintito_aws-vpc"]
#   }
# }

# output "vpc_id" {
#   value = data.aws_vpc.specific.id
# }
