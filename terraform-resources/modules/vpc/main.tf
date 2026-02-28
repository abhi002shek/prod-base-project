# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name                                        = "${var.environment}-vpc"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.environment}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name                                        = "${var.environment}-public-subnet-${count.index + 1}"
      "kubernetes.io/role/elb"                    = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
}

# Private Subnets - Frontend (EKS Worker Nodes)
resource "aws_subnet" "private_frontend" {
  count             = length(var.private_frontend_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_frontend_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name                                        = "${var.environment}-private-frontend-subnet-${count.index + 1}"
      "kubernetes.io/role/internal-elb"           = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      Tier                                        = "frontend"
    }
  )
}

# Private Subnets - Backend (EKS Worker Nodes)
resource "aws_subnet" "private_backend" {
  count             = length(var.private_backend_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_backend_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name                                        = "${var.environment}-private-backend-subnet-${count.index + 1}"
      "kubernetes.io/role/internal-elb"           = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      Tier                                        = "backend"
    }
  )
}

# Private Subnets - Database
resource "aws_subnet" "private_database" {
  count             = length(var.private_database_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_database_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-private-database-subnet-${count.index + 1}"
      Tier = "database"
    }
  )
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? length(var.availability_zones) : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.environment}-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? length(var.availability_zones) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.environment}-nat-gateway-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route Table - Public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-public-rt"
  })
}

# Route Table Association - Public
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Tables - Private Frontend
resource "aws_route_table" "private_frontend" {
  count  = length(var.private_frontend_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.enable_nat_gateway ? aws_nat_gateway.main[count.index].id : null
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-private-frontend-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "private_frontend" {
  count          = length(aws_subnet.private_frontend)
  subnet_id      = aws_subnet.private_frontend[count.index].id
  route_table_id = aws_route_table.private_frontend[count.index].id
}

# Route Tables - Private Backend
resource "aws_route_table" "private_backend" {
  count  = length(var.private_backend_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.enable_nat_gateway ? aws_nat_gateway.main[count.index].id : null
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-private-backend-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "private_backend" {
  count          = length(aws_subnet.private_backend)
  subnet_id      = aws_subnet.private_backend[count.index].id
  route_table_id = aws_route_table.private_backend[count.index].id
}

# Route Tables - Private Database
resource "aws_route_table" "private_database" {
  count  = length(var.private_database_cidrs)
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.environment}-private-database-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "private_database" {
  count          = length(aws_subnet.private_database)
  subnet_id      = aws_subnet.private_database[count.index].id
  route_table_id = aws_route_table.private_database[count.index].id
}

# VPC Flow Logs
resource "aws_flow_log" "main" {
  count                = var.enable_flow_logs ? 1 : 0
  iam_role_arn         = aws_iam_role.flow_logs[0].arn
  log_destination      = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
  max_aggregation_interval = 60

  tags = merge(var.tags, {
    Name = "${var.environment}-vpc-flow-logs"
  })
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/aws/vpc/${var.environment}-flow-logs"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.environment}-vpc-flow-logs-policy"
  role  = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}
