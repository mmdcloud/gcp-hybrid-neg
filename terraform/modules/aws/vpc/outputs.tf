output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "vpc_main_route_table_id" {
  value = module.vpc.vpc_main_route_table_id
}

output "default_route_table_id" {
  value = module.vpc.default_route_table_id
}

output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}

output "public_route_table_ids" {
  value = module.vpc.public_route_table_ids
}

output "default_vpc_main_route_table_id" {
  value = module.vpc.vpc_main_route_table_id
}