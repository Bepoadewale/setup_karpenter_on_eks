terraform {
  backend "s3" {
    bucket         = "eks-deploy-html-website"
    key            = "html-app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
