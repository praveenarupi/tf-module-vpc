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
  ngw = try(each.value["ngw"], false)
  igw = try(each.value["igw"], false)
  env = var.env
  // igw_id = aws_internet_gateway.igw.id
  // route_tables = aws_route_table.route-tables
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-igw"
  }
}

resource "aws_route_table" "route-tables" {
  for_each = var.subnets
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${each.value["name"]}-rt"
  }
}

resource "aws_route" "public" {
  route_table_id = aws_route_table.route-tables["public"].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

//resource "aws_route" "private-apps" {
//  route_table_id = aws_route_table.route-tables["public"].id
// destination_cidr_block = "0.0.0.0/0"
//  gateway_id = aws_internet_gateway.igw.id
//}
//
//resource "aws_route" "private-db" {
//  route_table_id = aws_route_table.route-tables["public"].id
//  destination_cidr_block = "0.0.0.0/0"
//  gateway_id = aws_internet_gateway.igw.id
//}

output "out" {
  value = module.subnets["public"].out.id
}