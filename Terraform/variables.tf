variable "aws_region" {
    description = "AWS region where resource will be provisioned"
    default =  "ap-south-1"
  
}

variable "ami_id" {
    description = "AMI ID for the ec2 instance"
    default = "ami-0e35ddab05955cf57"
}

variable "instance_type" {
    description = "Instance type for the ec2 instance"
    default = "t2.large"
}

variable "my_environment" {
    description = "Instance type for the ec2 instance"
    default = "Dev"
  
}