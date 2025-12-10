terraform {
  backend "http" {
    address       = "http://your-ip:8080/terraform_state/my_state"
    lock_address  = "http://your-ip:8080/terraform_lock/my_state"
    unlock_address = "http://your-ip:8080/terraform_lock/my_state"

    lock_method   = "PUT"
    unlock_method = "DELETE"

    # Optional authenticated requests
    username = "terraform"
    password = "ops-admin"
  }
}
