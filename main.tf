resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = {
    Name =  "${var.env}-vpc"
  }
}

module "subnets" {
  for_each = var.subnets
  source = "./subnets"
  name = each.value["name"]
  subnets = each.value["subnet_cidr"]
  vpc_id = aws_vpc.main.id
  AZ = var.AZ
  env = var.env
}

module "routes" {
  for_each = var.subnets
  source = "./routes"
  vpc_id = aws_vpc.main.id
  name = each.value["name"]
  subnet_ids = module.subnets
  gateway_id = aws_internet_gateway.igw.id
  nat_gateway_id = aws_nat_gateway.ngw.id
  ngw = try(each.value["ngw"], false)
  igw = try(each.value["igw"], false)
  default_vpc_cidr = var.default_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering-to-default-vpc.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-igw"
  }
}

resource "aws_eip" "ngw" {
  vpc = true
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw.id
  subnet_id     = module.subnets["public"].out[0].id
  tags = {
    Name = "${var.env}-ngw"
  }
}

resource "aws_vpc_peering_connection" "peering-to-default-vpc" {
  peer_vpc_id = aws_vpc.main.id
  vpc_id      = var.default_vpc_id
  auto_accept = true
}
