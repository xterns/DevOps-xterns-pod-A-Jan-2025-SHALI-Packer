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

  provisioner "file" {
    source      = "./scripts/001-critical-standards.sh"
    destination = "/tmp/001-critical-standards.sh"
  }

  provisioner "shell" {
    inline = [
      "sleep 30",
      "chmod +x /tmp/001-critical-standards.sh",
      "sudo /tmp/001-critical-standards.sh",
    ]
  }

  provisioner "file" {
    source      = "./scripts/002-critical-standards.sh"
    destination = "/tmp/002-critical-standards.sh"
  }

  provisioner "shell" {
    inline = [
      "if [ -f /tmp/002-critical-standards.sh ]; then",
      "  chmod +x /tmp/002-critical-standards.sh",
      "  sudo /tmp/002-critical-standards.sh || exit 1",
      "else",
      "  echo 'Error: /tmp/002-critical-standards.sh not found'; exit 1",
      "fi"
    ]
  }
}
