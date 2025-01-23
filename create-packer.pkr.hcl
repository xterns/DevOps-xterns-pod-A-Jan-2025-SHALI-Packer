packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  region = "us-east-1"
  source_ami = "ami-04b4f1a9cf54c11d0"
  instance_type  = "t2.small"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
  ami_name       = "packer_AWS_xtern_Jan24_{{timestamp}}"
}

build {
  name = "xtern-amazon-ebs"
  sources = [ "source.amazon-ebs.ubuntu"]
}
