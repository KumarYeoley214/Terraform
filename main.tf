#taking provider :: it provide AWS enviroment and necessary plugin & region & access key and secreat key
provider "aws" {
  region     = "ap-south-1"
  access_key = "AKIARZ6MVEHTLMDLEAFM"
  secret_key = "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"
}

# creating EC2 instance 
resource "aws_instance" "web-server-instance"{
    ami = "ami-068257025f72f470d"
    instance_type = "t2.micro"
}


# create VPC
resource "aws_vpc" "prod-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
      Name = "production"
    }
  
}
# terraform security groups :: ingress and egress (inbound and outbound)
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow  Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}


