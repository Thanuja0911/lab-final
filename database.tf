resource "aws_db_instance" "db" {
  allocated_storage    = 5
  engine               = "mysql"
  engine_version       = "8.0"  # You can choose the desired MySQL version
  instance_class       = "db.t4g.micro"
  username             = "replica_mysql"
  password             = "UberSecretPassword"
  identifier           = "chatconnect-db-mysql"
  
  port                 = "3306"
  publicly_accessible  = false
  storage_encrypted    = true
  kms_key_id           = aws_kms_key.rds_encryption.arn
  backup_retention_period = 7  # Enable automated backups

  db_subnet_group_name = aws_db_subnet_group.main_db_subnet_group.name
  skip_final_snapshot = true 

  tags = {
    Name = "Primary MySQL DB"
  }
}


# Read Replica Instance
resource "aws_db_instance" "read_replica" {
  replicate_source_db  = aws_db_instance.db.identifier
  instance_class       = "db.t4g.micro"
  publicly_accessible  = false
  storage_encrypted    = true
  kms_key_id           = aws_kms_key.rds_encryption.arn

  tags = {
    Name = "Read Replica DB"
  }
}

module "db_rds" {
  source = "terraform-aws-modules/rds/aws"

  identifier        = "demodb"
  engine            = "postgres"
  engine_version    = "13.13"
  instance_class    = "db.t4g.micro"
  allocated_storage = 5

  db_name                     = "replicaPostgresql"
  username                    = "replica_postgresql"
  password                    = "UberSecretPassword"
  port                        = "5432"
  manage_master_user_password = false
  apply_immediately           = true

  backup_retention_period = 1 # Set to at least 1 to enable backups, here 7 days
  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  vpc_security_group_ids = [module.db_security_group.security_group_id]
  create_db_subnet_group = true
  subnet_ids             = module.vpc.database_subnets
  family = "postgres13"
  deletion_protection = false
}

module "replica" {
  source = "terraform-aws-modules/rds/aws"
  identifier = "demodb-replica"
  replicate_source_db = module.db_rds.db_instance_arn
  engine            = "postgres"
  engine_version    = "13.13"
  instance_class    = "db.t4g.micro"
  allocated_storage = 5
  port              = "5432"
  multi_az                = false
  vpc_security_group_ids  = [module.db_security_group.security_group_id]
  maintenance_window      = "Tue:00:00-Tue:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 0

  family              = "postgres13"
  skip_final_snapshot = true
}

# KMS Key for RDS Encryption
resource "aws_kms_key" "rds_encryption" {
  description = "KMS key for RDS instance encryption"
  key_usage   = "ENCRYPT_DECRYPT"
}

# KMS Key for S3 Bucket Encryption
resource "aws_kms_key" "s3_encryption" {
  description = "KMS key for S3 bucket encryption"
  key_usage   = "ENCRYPT_DECRYPT"
}

# S3 Bucket
resource "aws_s3_bucket" "storage_bucket" {
  bucket = "chatconnect-storage-bucket"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "storage_bucket_sse" {
  bucket = aws_s3_bucket.storage_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# Optional: S3 Bucket Policy for Secure Access
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.storage_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "${aws_s3_bucket.storage_bucket.arn}",
        "${aws_s3_bucket.storage_bucket.arn}/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": false
        }
      }
    }
  ]
}
POLICY
}

# output "rds_endpoint" {
#   value = module.main_db.db_instance_address
# }