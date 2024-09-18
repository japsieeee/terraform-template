provider "aws" {
  access_key = var.aws_acces_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}

# # private key

# resource "tls_private_key" "project24_private_key" {
#   algorithm = "RSA"
# }

# resource "aws_key_pair" "generated_key" {
#   key_name   = `${tls_private_key.project24_private_key}`
#   public_key = tls_private_key.project24_private_key.public_key_openssh
#   depends_on = [
#     tls_private_key.project24_private_key
#   ]
# }

# create vpc for servers

resource "aws_vpc" "project24_vpc" {
  cidr_block         = var.cidr_block
  instance_tenancy   = "default"
  enable_dns_support = "true"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "project24_subnet" {
  vpc_id            = aws_vpc.project24_vpc.id
  cidr_block        = "10.0.1.0/24"  # Adjust as needed
  availability_zone = var.aws_region # Specify your desired availability zone

  tags = {
    Name = "project24_subnet"
  }
}


# create and configure security group
resource "aws_security_group" "project24_security_group_name" {
  name        = "project24_security_group_name"
  description = "This firewall allows SSH, HTTP and MYSQL"
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project24_security_group_name"
  }
}

resource "aws_instance" "dividend_and_queue_instance" {
  ami = "ami-056a29f2eddc40520" # ubuntu jammy v22.04
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.project24_subnet.id
  private_ip    = "10.0.1.185" 

  tags = {
    "name" = dividend_queue
  }
}

resource "aws_instance" "main_instance" {
  ami = "ami-056a29f2eddc40520" # ubuntu jammy v22.04
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.project24_subnet.id
  private_ip    = "10.0.1.190" 
  
  tags = {
    "name" = main
  }
}