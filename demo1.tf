

# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 4.0"
#     }
#   }
# }

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket         = "tf-action"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    # dynamodb_table = "<your_dynamo_dbtable_name>"
  }
}

# Configure the AWS Provider
provider "aws" {
    region = "us-east-1"


    # profile = "terraform"
}

# Create a VPC
resource "aws_vpc" "TF_Example" {
  cidr_block = "10.0.0.0/16"
  
    
  tags = {
    Name = "tf-example"
  }
}

# Create Security Groups
resource "aws_security_group" "ec2-ssh_http" {
  //name = “sg_ec2-ssh_http”
  description = "SSH and HTTP Ingress via Terraform"
  vpc_id = aws_vpc.TF_Example.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description =  "HTTP Ingress"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description =  "SSH Ingress"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
##########################


# Create Network components
resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.TF_Example.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tf-example"
  }
}

resource "aws_internet_gateway" "tf_example-ig" {
  vpc_id = aws_vpc.TF_Example.id
}

resource "aws_route_table" "tf_example-rt" {
  vpc_id = aws_vpc.TF_Example.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_example-ig.id
  }
}

resource "aws_route_table_association" "tf_example-rta" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.tf_example-rt.id
}
############################################


# Create Keys
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tf_key" {
    key_name = "tf_key"
    public_key = tls_private_key.this.public_key_openssh
}

resource "local_file" "tfkey" {
  content  = tls_private_key.this.private_key_pem
  filename = "tf_key.pem"
  file_permission = "600"
  directory_permission = "700"
}
########################


# Create EC2
resource "aws_instance" "tf-example" {
    ami           = "ami-0aa7d40eeae50c9a9"
    instance_type = "t2.micro"
    associate_public_ip_address = true
    vpc_security_group_ids = [aws_security_group.ec2-ssh_http.id]
    subnet_id =  aws_subnet.my_subnet.id
    key_name = aws_key_pair.tf_key.key_name
    


  tags = {
    Name = "Rahul Guha"
  }
}