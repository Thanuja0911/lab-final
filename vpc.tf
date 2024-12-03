module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "my-vpc"
  cidr = "172.16.0.0/16"
  azs = ["us-west-1a", "us-west-1c"]
  public_subnets = ["172.16.102.0/24", "172.16.202.0/24"]
  private_subnets = ["172.16.101.0/24", "172.16.201.0/24"]
  database_subnets = ["172.16.103.0/24", "172.16.203.0/24"]
  create_database_subnet_group = true
  map_public_ip_on_launch = true
  create_igw = true
  enable_nat_gateway = true
  single_nat_gateway = false 
  public_subnet_tags = {
    "Name" = "Public Subnet"
  }
  private_subnet_tags = {
    "Name" = "Private Subnet"
  }
}

resource "aws_db_subnet_group" "main_db_subnet_group" {
  name       = "main-db-subnet-group"
  subnet_ids = module.vpc.database_subnets 
  tags = {
    Name = "main-db-subnet-group"
  }
}

resource "aws_eip" "nat_eip" {
  vpc = true

  tags = {
    Name = "NAT Gateway EIP"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = module.vpc.public_subnets[0] 

  tags = {
    Name = "Main NAT Gateway"
  }
}

output "vpc-id" {
  value = module.vpc.vpc_id
}
