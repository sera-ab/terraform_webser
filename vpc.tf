#### VPC Module ####

module "vpc" { 
  source = "./vpc" 

  availability_zones             = var.availability_zones
  nat_count                      = "1"
  network                        = var.network
  app                            = var.app
}

#### VPC Resources ####
resource "aws_vpc" "vpc" {
  cidr_block           = "${var.network["cidr"]}"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  instance_tenancy     = "default"

  tags = {
    Name        = "${var.app["name"]}-${var.app["env"]}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name        = "${var.app["name"]}-${var.app["env"]}-igw"
  }
} 

resource "aws_eip" "nat" {
  count = "${var.nat_count}"
  vpc   = true

  tags = {
    Name        = "${var.app["name"]}-${var.app["env"]}-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  count         = "${var.nat_count}"
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"

  tags = {
    Name        = "${var.app["name"]}-${var.app["env"]}-ng"
  }
}

resource "aws_subnet" "public" {
  count             = "2"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${var.network["publicAz${count.index + 1}"]}"
  availability_zone = "${var.availability_zones["${count.index}"]}"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.app["name"]}-${var.app["env"]}-sn-public"
  }
}

resource "aws_subnet" "private" {
  count             = "2"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${var.network["privateAz${count.index + 1}"]}"
  availability_zone = "${var.availability_zones["${count.index}"]}"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.app["name"]}-${var.app["env"]}-sn-private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name        = "${var.app["name"]}-${var.app["env"]}-rt-public"
  }
}

resource "aws_route" "public" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

resource "aws_route_table_association" "public" {
  count          = "2"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.vpc.id}"
  count  = "2"

  tags = {
    Name        = "${var.app["name"]}-${var.app["env"]}-rt-private"
  }
}

resource "aws_route" "private" {
  count                  = "2"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  nat_gateway_id         = "${var.nat_count == "1" ? aws_nat_gateway.nat.0.id : element(aws_nat_gateway.nat.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private" {
  count = "2"

  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_security_group" "main" {
  name        = "${var.app["name"]}-${var.app["env"]}-sg-default"
  description = "Default VPC security group"
  vpc_id      = "${aws_vpc.vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app["name"]}-${var.app["env"]}-sg-default"
  }
}

resource "aws_route53_zone" "main" {
  name          = "${var.app["name"]}-${var.app["env"]}.internal"
  force_destroy = true

  vpc {
    vpc_id = "${aws_vpc.vpc.id}"
  }

  lifecycle {
    ignore_changes = [vpc]
  }
}




