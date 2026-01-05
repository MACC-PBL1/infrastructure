# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.name}-vpc" }
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.name}-igw" }
}

# Public Subnets (2 AZs)
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  
  tags = { 
    Name = "${var.name}-public-${count.index + 1}"
  }
}

# Private Subnets (2 AZs)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  
  tags = { 
    Name = "${var.name}-private-${count.index + 1}"
  }
}

# EIP para NAT Gateways
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 2 : 0
  domain = "vpc"
  
  tags = { 
    Name = "${var.name}-nat-eip-${count.index + 1}"
  }
}

# NAT Gateways (uno por AZ para alta disponibilidad)
resource "aws_nat_gateway" "nat" {
  count         = var.enable_nat_gateway ? 2 : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = { 
    Name = "${var.name}-nat-${count.index + 1}"
  }
  
  depends_on = [aws_internet_gateway.this]
}

# Route Table - Public (compartida por ambas subnets públicas)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id
  
  tags = { Name = "${var.name}-public-rt" }
}

resource "aws_route" "default_public" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Route Tables - Private (una por AZ, cada una con su NAT Gateway)
resource "aws_route_table" "private_rt" {
  count  = 2
  vpc_id = aws_vpc.this.id
  
  tags = { 
    Name = "${var.name}-private-rt-${count.index + 1}"
  }
}

resource "aws_route" "private_default" {
  count                  = var.enable_nat_gateway ? 2 : 0
  route_table_id         = aws_route_table.private_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id
}

resource "aws_route_table_association" "private_assoc" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}