/* 1. Creating Virtual Private Cloud [VPC] */

resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"
    enable_dns_hostnames = "true"
  tags = merge( local.common_tags, {
    Name = "${var.project}-${var.environment}"
  }
 )
}

/* 2. So VPC need a gate to its infra so here we call it as INTERNET GATE WAY to allow inbound and outbound traffic */

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge( local.common_tags, {
    Name = "${var.project}-${var.environment}"
  }
  )
}

/* 3. Creating SUBNETS for public,private and database servers */

resource "aws_subnet" "public" {
  count = length(var.public_cidr_block)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_cidr_block[count.index]
  availability_zone = local.azs[count.index]
  map_public_ip_on_launch = true 
   
 tags = merge( local.common_tags, {
    Name = "${var.project}-${var.environment}-public-${local.azs[count.index]}"
  }
  )
}

resource "aws_subnet" "private" {
  count = length(var.private_cidr_block)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_cidr_block[count.index]
  availability_zone = local.azs[count.index]

 tags = merge( local.common_tags, {
    Name = "${var.project}-${var.environment}-private-${local.azs[count.index]}"
  }
  )
}

resource "aws_subnet" "database" {
  count = length(var.database_cidr_block)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_cidr_block[count.index]
  availability_zone = local.azs[count.index]

 tags = merge( local.common_tags, {
    Name = "${var.project}-${var.environment}-database-${local.azs[count.index]}"
  }
  )
}

/* 4. Creating Elastic IP and NAT gateway so as the private and database servers can fetch sources from outside 
       NOTE: Only outgoing traffic is allowed no incoming and NAT gateway will be attaced with public subnets */

resource "aws_eip" "nat" {
    domain   = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

 
 tags = merge( local.common_tags, {
    Name = "${var.project}-${var.environment}"
  }
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

/* 5. Creating Route Tables for Public,Private and Database */

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

 tags = merge( local.common_tags, {
    Name = "${var.project}-${var.environment}-public"
  }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

 tags = merge( local.common_tags, {
    Name = "${var.project}-${var.environment}-private"
  }
  )
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

 tags = merge( local.common_tags, {
    Name = "${var.project}-${var.environment}-database"
  }
  )
}

/* 6. Creating Routes */

resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
 gateway_id = aws_internet_gateway.gw.id
}

resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.nat_gw.id
}

resource "aws_route" "database" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
   gateway_id = aws_nat_gateway.nat_gw.id
}

/* 7. Creating route table associations */

resource "aws_route_table_association" "public" {
  count = length(var.public_cidr_block)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_cidr_block)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count = length(var.database_cidr_block)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

