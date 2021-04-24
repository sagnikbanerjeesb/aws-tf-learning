terraform {
  backend "s3" {
    bucket = "sgb-tf-state"
    key    = "demo-tf-state"
    region = "us-east-1"
  }
}