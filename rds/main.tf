provider "aws" {
  region = "ap-northeast-1"
}

##############################################################
# Data sources to get VPC, subnets and security group details
##############################################################
data "aws_vpc" "selected" {
  id = "vpc-01b2caf4c15eaab98"
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.selected.id
}

data "aws_security_group" "aqua-all" {
  vpc_id = data.aws_vpc.selected.id
  name   = "aqua-all"
}

#####
# DB
#####
module "db" {
  source = "../../"

  identifier = "terraform-test"

  engine            = "oracle-se1"
  engine_version    = "11.2.0.4.v22"
  instance_class    = "db.t3.micro"
  allocated_storage = 10
  storage_encrypted = false
  license_model     = "bring-your-own-license"

  # Make sure that database name is capitalized, otherwise RDS will try to recreate RDS instance every time
  name                                = "tftest"
  username                            = "ariel"
  password                            = "arieladmin!"
  port                                = "1521"
  iam_database_authentication_enabled = false

  vpc_security_group_ids = [data.aws_security_group.aqua-all.id]
  maintenance_window     = "Mon:00:00-Mon:03:00"
  backup_window          = "03:00-06:00"

  # disable backups to create DB faster
  backup_retention_period = 0

  tags = {
    Environment = "dev"
  }

  # DB subnet group
  subnet_ids = data.aws_subnet_ids.all.ids

  # DB parameter group
  family = "oracle-se1-11.2"

  # DB option group
  major_engine_version = "11.2"

  # See here for support character sets https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.OracleCharacterSets.html
  character_set_name = "AL32UTF8"

  # Database Deletion Protection
  deletion_protection = false
}
