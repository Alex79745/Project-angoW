terraform {
  backend "s3" {
    bucket                      = "ceph-bucket"
    key                         = "kluster/proxmox-terraform/vm-from-tpl/terraform.tfstate"
    region                      = "us-east-1"
    endpoint                    = "http://192.168.1.129:7480"
    access_key                  = "DWZ2FNF5V793DTAPNJ6X"
    secret_key                  = "CL9M0mVU98ahgDAWkSGX3HkQjtrCfZ7qNDo0PEeM"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    force_path_style            = true
  }
}
