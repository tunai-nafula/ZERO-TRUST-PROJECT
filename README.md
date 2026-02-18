# ZERO TRUST EC2 INSTANCE ARCHITECTURE ON AWS USING TERRAFORM AND PACKER 

This repository sets up a Zero Trust AWS environment in which EC2 instances run in private subnets. They do not have public IPs, SSH access, inbound security group rules, or key pairs. 

You connect to the EC2 instances using the AWS Systems Manager (SSM) Session Manager over VPC interface endpoints. This eliminates the need for bastion hosts, SSH keys, or exposed ports. Therefore, a Network Address Translation (NAT) Gateway is not required.

The infrastructure is built using Terraform for reproducibility and Packer to create a hardened, reusable AMI with the SSM Agent preinstalled and configured. An Apache service is included to demonstrate secure access via SSM port forwarding.

This setup follows the Zero Trust principles: never trust the network, verify every access request, and minimize the attack surface.

Find the full documentation here: https://medium.com/@tunaimakokha/zero-trust-ec2-instance-architecture-on-aws-using-terraform-and-packer-c1920ddc2adc
