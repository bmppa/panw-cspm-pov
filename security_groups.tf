#
# Create security group
#

resource "aws_security_group" "internet_sg" {
  name        = "demo-internet-sg"
  description = "Allow ICMP, SSH inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "ICMP Access"
    from_port   = "-1"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Egress Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
