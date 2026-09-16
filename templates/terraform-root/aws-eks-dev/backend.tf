terraform {
  backend "s3" {
    bucket       = "autonomous-factory-tfstate-697091778198-us-west-2"
    key          = "autonomous-factory-demo/dev/terraform.tfstate"
    region       = "us-west-2"
    use_lockfile = true
    encrypt      = true
  }
}
