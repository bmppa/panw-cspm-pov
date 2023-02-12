
# Specify SSH key pair to use
variable "key_pair" {
  description = "What is the name of the Key Pair to use for the instance?"
  type        = string
}

# Define provider
provider "aws" {
  region = "us-east-1"
}

resource "random_string" "random" {
  length  = 4
  special = false
  upper   = false
}

# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "prisma-cloud-vpc-${random_string.random.result}"
    Proj = "prisma-cloud-pov-${random_string.random.result}"
  }
}

# Find available AZs
data "aws_availability_zones" "azs" {
  state = "available"
}

# Creates a public subnet
resource "aws_subnet" "pub_net" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = element(data.aws_availability_zones.azs.names, 0)

  tags = {
    Name = "pub-subnet-${random_string.random.result}"
    Proj = "prisma-cloud-pov-${random_string.random.result}"
  }
}

# Create an Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "internet-gateway-${random_string.random.result}"
    Proj = "prisma-cloud-pov-${random_string.random.result}"
  }
}

# Create route table with a default Internet route to Internet Gateway
resource "aws_route_table" "internet_route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name = "route-table-${random_string.random.result}"
    Proj = "prisma-cloud-pov-${random_string.random.result}"
  }
}

# Associate public subnet with a routing table
resource "aws_route_table_association" "default-route-assoc" {
  subnet_id      = aws_subnet.pub_net.id
  route_table_id = aws_route_table.internet_route.id
}

# Create a generic Ubuntu server
resource "aws_instance" "server" {
  count                       = 1
  ami                         = "ami-01d08089481510ba2"
  instance_type               = "t3a.small"
  subnet_id                   = aws_subnet.pub_net.id
  vpc_security_group_ids      = [aws_security_group.internet_sg.id]
  key_name                    = var.key_pair
  associate_public_ip_address = true
  monitoring                  = true
  user_data                   = file("install_docker.sh")

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "server-${count.index + 1}-${random_string.random.result}"
    Proj = "prisma-cloud-pov"
  }
}

# Create a bucket where objects can be public
resource "aws_s3_bucket" "public_bucket" {
  bucket = "my-public-bucket-${random_string.random.result}"

  tags = {
    Privacy = "public"
    Proj    = "prisma-cloud-pov"
  }
}

resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.public_bucket.id
  policy = templatefile("s3_public_policy.json", { bucket = "${aws_s3_bucket.public_bucket.id}" })
}

resource "aws_s3_object" "objects" {
  for_each = fileset("uploads/", "*")
  bucket   = aws_s3_bucket.public_bucket.id
  key      = each.value
  source   = "uploads/${each.value}"
}

output "vpc" {
  value = aws_vpc.vpc.id
}
output "server-1" {
  value = aws_instance.server[0].public_ip
}
output "public_s3_bucket" {
  value = aws_s3_bucket.public_bucket.bucket
}