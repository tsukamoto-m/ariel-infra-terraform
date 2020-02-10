provider "aws" {
  region = "ap-northeast-1"
}

locals {
  user_data = <<EOF
#!/bin/bash
echo "Hello Terraform!"
EOF
}

##################################################################
# Data sources to get VPC, subnet, security group and AMI details
##################################################################
data "aws_vpc" "selected" {
  id = "vpc-01b2caf4c15eaab98"
}

data "aws_subnet_ids" "aqua-all" {
  vpc_id = data.aws_vpc.selected.id
}

data "aws_security_group" "aqua-all" {
  vpc_id = data.aws_vpc.selected.id
  name   = "aqua-all"
}

#resource "aws_eip" "this" {
#  vpc      = true
#  instance = module.ec2.id[0]
#}

resource "aws_placement_group" "web" {
  name     = "hunky-dory-pg"
  strategy = "cluster"
}

resource "aws_network_interface" "this" {
  count = 1

  subnet_id = tolist(data.aws_subnet_ids.aqua-all.ids)[count.index]
}

module "ec2" {
  source = "../../"

  instance_count = 1

  name          = "example-normal"
  ami           = "ami-0817a2d674f452eb7"
  instance_type = "c5.large"
  subnet_id     = tolist(data.aws_subnet_ids.aqua-all.ids)[0]
  //  private_ips                 = ["172.31.32.5", "172.31.46.20"]
  vpc_security_group_ids      = [data.aws_security_group.aqua-all.id]
  associate_public_ip_address = true
  placement_group             = aws_placement_group.web.id

  user_data_base64 = base64encode(local.user_data)

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 30
    },
  ]

  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp2"
      volume_size = 5
      encrypted   = true
    }
  ]

  tags = {
    "Env"      = "Private"
    "Location" = "Secret"
  }
}


module "ec2_with_network_interface" {
  source = "../../"

  instance_count = 1

  name            = "example-network"
  ami             = "ami-0817a2d674f452eb7"
  instance_type   = "c5.large"
  placement_group = aws_placement_group.web.id

  network_interface = [
    {
      device_index          = 0
      network_interface_id  = aws_network_interface.this[0].id
      delete_on_termination = false
    }
  ]
}

# This instance won't be created
module "ec2_zero" {
  source = "../../"

  instance_count = 0

  name                   = "example-zero"
  ami                    = "ami-0817a2d674f452eb7"
  instance_type          = "c5.large"
  subnet_id              = tolist(data.aws_subnet_ids.aqua-all.ids)[0]
  vpc_security_group_ids = [data.aws_security_group.aqua-all.id]
}
