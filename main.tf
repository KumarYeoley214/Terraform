#taking provider :: it provide AWS enviroment and necessary plugin & region & access key and secreat key
provider "aws" {
  region     = "ap-south-1"
  access_key = "xxxxxxxxxxxxxxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxxxxxxx"
}

# 1. creating vpc (Virtual private cloud is a service that lets you launch AWS resources in a logically isolated virtual network that you define)

resource "aws_vpc" "prod-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
      Name = "production"
    }
  
}

# 2. Creating internet gatweay , 
#it enables resources in your public subnets (such as EC2) to connect to the internet if the resource has a public IPv4 or an IPv6 address  

resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.prod-vpc.id
}

# 3. Creating route table : determine where network traffic from your subnet or gateway is directed.

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id             = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}

# 4. Creating Subnet : a range of IP addresses in your VPC

resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1a"

    tags = {
      Name = "prod-subnet"
    }
  
}

# 5. Creating subnet route table association : determine where network traffic from your subnet or gateway is directed.

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. creating security group : acts as a virtual firewall for your EC2 instances to control incoming and outgoing traffic

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
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
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

  tags = {
    Name = "allow_web"
  }
}

# 7. create network interface : virtual network cards attached to EC2 instances that help facilitate network connectivity for instances

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# 8. elastic ip : reserved public IP address that you can assign to any EC2 instance in a particular region, until you choose to release it.

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]

}

# 9. creating Ubuntu server and install& enable apache2

resource "aws_instance" "web-server-instance"{
    ami = "ami-068257025f72f470d"
    instance_type = "t2.micro"
    availability_zone = "ap-south-1a"
    
    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.web-server-nic.id
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo my first web server > /var/www/html/index.html'
                EOF
    
    tags = {
        Name = "web-server"
    }
}
