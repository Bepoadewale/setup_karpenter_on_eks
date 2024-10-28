terraform {
  backend "s3" {
    bucket         = "eks-deploy-html-website-aws-autoscaling-group"
    key            = "html-app/terraform.tfstate"
    region         = "us-east-1"
  }
}