
terraform {
  backend "s3" {
    bucket         = "terraformbucketroute"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terrformdynamodb"
    encrypt        = true
  }
  
}