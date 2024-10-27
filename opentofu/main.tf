variable "aws_region" {
  default = "ap-south-1"
}

variable "base_cidr_block" {
  description = "A /16 CIDR range definition, such as 10.1.0.0/16, that the VPC will use"
  default = "10.1.0.0/16"

  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^(?:\\d{1,3}\\.){3}\\d{1,3}\\/(?:[0-9]|[1-2][0-9]|3[0-2])$", var.base_cidr_block))
    error_message = "The base_cidr_block variable value should be a valid cidr"
  }
}

variable "availability_zones" {
  description = "A list of availability zones in which to create subnets"
  type = list(string)
  default = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

locals {
  aws_module_version = "5.6.1"
}

terraform {
  backend "s3" {
    region = var.aws_region
  }

  required_providers {
    aws = {
      source  = "opentofu/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  # Referencing the base_cidr_block variable allows the network address
  # to be changed without modifying the configuration.
  cidr_block = var.base_cidr_block

}

resource "aws_subnet" "az" {
  # Create one subnet for each given availability zone.
  count = length(var.availability_zones)

  # For each subnet, use one of the specified availability zones.
  availability_zone = var.availability_zones[count.index]

  # By referencing the aws_vpc.main object, OpenTofu knows that the subnet
  # must be created only after the VPC is created.
  vpc_id = aws_vpc.main.id

  # Built-in functions and operators can be used for simple transformations of
  # values, such as computing a subnet address. Here we create a /20 prefix for
  # each subnet, using consecutive addresses for each availability zone,
  # such as 10.1.16.0/20 .
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index+1)
}

# attributes as block mode
resource "aws_security_group" "example" {

  # egress {
  #   from_port        = 0
  #   to_port          = 0
  #   protocol         = "-1"
  #   cidr_blocks      = ["0.0.0.0/0"]
  #   ipv6_cidr_blocks = ["::/0"]
  # }

  egress = []

}

/*

check "health_check" {
  data "http" "opentofu_org_check" {
    url = "https://www.opentofu.orggg"

    depends_on = [ aws_security_group.example ]
  }

  assert {
    condition = data.http.opentofu_org_check.status_code == 200
    error_message = "${data.http.opentofu_org_check.url} returned an unhealthy status code"
  }
  
}

data "http" "opentofu_org_post_condition" {
  url = "https://www.opentofu.org"

  lifecycle {
    postcondition {
        condition = self.status_code == 200
        error_message = "${self.url} returned an unhealthy status code"
    }
  }

  depends_on = [ aws_security_group.example ]
}

*/

# │ Warning: Check block assertion failed
# │ 
# │   on main.tf line 103, in check "health_check_vpc":
# │  103:     condition = data.aws_vpc.main_check.enable_dns_hostnames == true
# │     ├────────────────
# │     │ data.aws_vpc.main_check.enable_dns_hostnames is false
# │ 
# │ aws_vpc main vpc-0f714904fe95b2ee4 dns hostnames is not false

check "health_check_vpc" {
  data "aws_vpc" "main_check" {
    id = aws_vpc.main.id
  }

  assert {
    condition = data.aws_vpc.main_check.enable_dns_hostnames == true
    error_message = "aws_vpc main ${aws_vpc.main.id} dns hostnames is not false"
  }
}

/*
# │ Error: Your query returned no results. Please change your search criteria and try again.
# │ 
# │   with data.aws_ami.example,
# │   on main.tf line 108, in data "aws_ami" "example":
# │  108: data "aws_ami" "example" {
# │ 
# ╵

data "aws_ami" "example" {
  most_recent = true

  owners = ["self"]
  tags = {
    Name   = "app-server"
    Tested = "true"
  }
}

*/

data "aws_ami" "example" {
  owners = ["amazon"]

  filter {
    name   = "image-id"
    values = ["ami-04a37924ffe27da53"]
  }
}

/*
resource "aws_instance" "example" {
  instance_type = "t3.micro"
  ami           = data.aws_ami.example.id
  root_block_device {
    encrypted = true
  }

  lifecycle {
    # The AMI ID must refer to an AMI that contains an operating system
    # for the `x86_64` architecture.
    precondition {
      condition     = data.aws_ami.example.architecture == "x86_64"
      error_message = "The selected AMI must be for the x86_64 architecture."
    }

    # The EC2 instance must be allocated a public DNS hostname.
    postcondition {
      condition     = self.public_dns != ""
      error_message = "EC2 instance must be in a VPC that has public DNS hostnames enabled."
    }
  }
}

# │ Error: Resource postcondition failed
# │ 
# │   on main.tf line 196, in data "aws_ebs_volume" "example":
# │  196:       condition     = self.encrypted
# │     ├────────────────
# │     │ self.encrypted is false
# │ 
# │ The server's root volume is not encrypted.

data "aws_ebs_volume" "example" {
  # Use data resources that refer to other resources to
  # load extra data that isn't directly exported by a resource.
  #
  # Read the details about the root storage volume for the EC2 instance
  # declared by aws_instance.example, using the exported ID.

  filter {
    name = "volume-id"
    values = [aws_instance.example.root_block_device[0].volume_id]
  }

  # Whenever a data resource is verifying the result of a managed resource
  # declared in the same configuration, you MUST write the checks as
  # postconditions of the data resource. This ensures OpenTofu will wait
  # to read the data resource until after any changes to the managed resource
  # have completed.
  lifecycle {
    # The EC2 instance will have an encrypted root volume.
    postcondition {
      condition     = self.encrypted
      error_message = "The server's root volume is not encrypted."
    }
  }
}

output "api_base_url" {
  value = "https://${aws_instance.example.private_dns}:8433/"
}
*/