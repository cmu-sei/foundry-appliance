terraform {
  backend "s3" {
    region         = "us-east-1"
    key            = "proxmox/terraform.tfstate"
    bucket         = "foundry-proxmox"
    dynamodb_table = "foundry-proxmox-locks"
  }
}
