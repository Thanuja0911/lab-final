resource "aws_elasticache_parameter_group" "redis_params" {
  name        = "redis-parameter-group"
  family      = "redis6.x"
  description = "Custom Redis parameter group"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"  # Eviction policy for cache memory
  }
}

# Subnet Group for Redis
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group"
  subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]  # Private subnets

  tags = {
    Name = "Redis Subnet Group"
  }
}

# Redis Cache Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "redis-cluster"
  engine               = "redis"
  engine_version       = "6.x"
  node_type            = "cache.t2.micro"  # Change as per your needs
  num_cache_nodes      = 1  # Single node for simplicity, increase for HA
  parameter_group_name = aws_elasticache_parameter_group.redis_params.name
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids   = [aws_security_group.cache_sg.id]

  tags = {
    Name = "Redis Cache Cluster"
  }
}
