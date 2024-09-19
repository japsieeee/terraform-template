provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}

resource "tls_private_key" "project24_private_key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "generated_key" {
  key_name   = "project24_ec2_keypair"
  public_key = tls_private_key.project24_private_key.public_key_openssh
  depends_on = [
    tls_private_key.project24_private_key
  ]
}

resource "local_file" "private_key_pem" {
  filename      = "${path.module}/project24_ec2_keypair.pem"
  content       = tls_private_key.project24_private_key.private_key_pem
  file_permission = "0600"  # Ensure only you have access to the file
}

output "private_key_pem" {
  value     = tls_private_key.project24_private_key.private_key_pem
  sensitive = true  # Hides the private key from being shown in the CLI output
}

# Create a VPC for your servers
resource "aws_vpc" "project24_vpc" {
  cidr_block         = var.cidr_block
  instance_tenancy   = "default"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "main"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "project24_igw" {
  vpc_id = aws_vpc.project24_vpc.id

  tags = {
    Name = "project24_igw"
  }
}

# Create a route table with a route to the Internet Gateway
resource "aws_route_table" "project24_route_table" {
  vpc_id = aws_vpc.project24_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project24_igw.id
  }

  tags = {
    Name = "project24_route_table"
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "project24_subnet_association" {
  subnet_id      = aws_subnet.project24_subnet.id
  route_table_id = aws_route_table.project24_route_table.id
}

# Create a subnet within the VPC
resource "aws_subnet" "project24_subnet" {
  vpc_id            = aws_vpc.project24_vpc.id
  cidr_block        = "10.0.1.0/24" # Adjust as needed
  availability_zone = var.aws_az    # Specify your desired availability zone

  tags = {
    Name = "project24_subnet"
  }
}

# Create and configure the security group
resource "aws_security_group" "project24_security_group" {
  name        = "project24_security_group"
  description = "This firewall allows SSH, HTTP, MySQL, Redis, MongoDB, and ICMP"
  vpc_id      = aws_vpc.project24_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Redis"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MongoDB"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Ping (ICMP)"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project24_security_group"
  }
}

# EC2 instance for dividend and queue
resource "aws_instance" "dividend_and_queue_instance" {
  ami                         = "ami-056a29f2eddc40520" # ubuntu jammy v22.04
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.project24_subnet.id
  associate_public_ip_address = true
  private_ip                  = "10.0.1.185"
  availability_zone           = var.aws_az
  key_name                    = aws_key_pair.generated_key.key_name

  vpc_security_group_ids      = [aws_security_group.project24_security_group.id]

  tags = {
    Name = "dividend_queue"
  }
}

# EC2 instance for main
resource "aws_instance" "main_instance" {
  ami                         = "ami-056a29f2eddc40520" # ubuntu jammy v22.04
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.project24_subnet.id
  associate_public_ip_address = true
  private_ip                  = "10.0.1.190"
  availability_zone           = var.aws_az
  key_name                    = aws_key_pair.generated_key.key_name

  vpc_security_group_ids      = [aws_security_group.project24_security_group.id]

  tags = {
    Name = "main"
  }
}

# Output the public IPs of the EC2 instances
output "instance_public_ips" {
  value = [aws_instance.dividend_and_queue_instance.public_ip, aws_instance.main_instance.public_ip]
}
