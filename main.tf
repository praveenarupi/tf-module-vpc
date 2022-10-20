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

module "routes" {
  for_each = var.subnets
  source = "./routes"
  vpc_id = aws_vpc.main.id
  name = each.value["name"]
  subnet_ids = module.subnets
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


//resource "aws_route" "public" {
//  route_table_id = aws_route_table.route-tables["public"].id
//  destination_cidr_block = "0.0.0.0/0"
//  gateway_id = aws_internet_gateway.igw.id
//}
//resource "aws_route_table_association" "public" {
//  count = length(module.subnets["public"].out[*].id)
//  subnet_id = element(module.subnets["public"].out[*].id, count.index)
//  route_table_id = aws_route_table.route-tables["public"].id
//}
//resource "aws_route" "private-apps" {
//  route_table_id = aws_route_table.route-tables["apps"].id
//  destination_cidr_block = "0.0.0.0/0"
//  nat_gateway_id = aws_nat_gateway.ngw.id
//}
//resource "aws_route" "private-db" {
//  route_table_id = aws_route_table.route-tables["db"].id
//  destination_cidr_block = "0.0.0.0/0"
//  nat_gateway_id = aws_nat_gateway.ngw.id
//}
//resource "aws_route_table_association" "apps" {
//  count = length(module.subnets["apps"].out[*].id)
//  subnet_id = element(module.subnets["apps"].out[*].id, count.index)
//  route_table_id = aws_route_table.route-tables["apps"].id
//}

//resource "aws_vpc_peering_connection" "peering-to-default-vpc" {
//  peer_vpc_id = aws_vpc.main.id
//  vpc_id      = var.default_vpc_id
//  auto_accept = true
//}

//resource "aws_route" "peering" {
//  count = length(aws_route_table.route-tables["*"].id)
//  route_table_id = element(aws_route_table.route-tables[*].id, count.index)
//  destination_cidr_block = var.default_vpc_cidr
//  vpc_peering_connection_id = aws_vpc_peering_connection.peering-to-default-vpc.id
//}
