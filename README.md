# AWS Infrastructure Setup Documentation

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Variables](#variables)
4. [Resources Created](#Resources-Created)
5. [Usage](#usage)
6. [Cleanup](#cleanup)

## Overview

This Terraform configuration defines an AWS infrastructure setup that includes a Virtual Private Cloud (VPC), subnets, security groups, an ECS (Elastic Container Service) cluster, two Fargate task definitions, two ECS services and an application load balancer for high availability. This setup enables hosting HTML web pages on AWS with the help of an application load balancer and attaching an efs volume to the ECS Cluster.

## Prerequisites

 - Terraform: Installed on your local machine.
 - AWS Account: An AWS account with appropriate permissions to create the specified resources.

## Variables Configuration: A configured variables.tf file containing values for the following variables:

 - vpc_cidr: The CIDR block for the VPC.
 - public_subnet_cidr_1: The CIDR block for the first public subnet.
 - public_subnet_cidr_2: The CIDR block for the second public subnet.
 - private_subnet_cidr: The CIDR block for the private subnet.
 - aws_region: The AWS region where the resources will be created
 - cluster_name: The name of the ECS cluster.
 - task_definition_family: The family name for the ECS task definitions.
 - service_name: The name of the ECS service.
 - alb_name: The name of the Application Load Balancer.
 - target_group_name: The name of the target group.

 


## Resources Created

 1. **VPC**:
 
	- Resource Type: aws_vpc
	- Description: Creates a VPC to host the resources, providing a secure and isolated network.

 2. **Internet Gateway**:
	
	- Resource Type: aws_internet_gateway
	- Description: Creates an internet gateway to provide internet access to the VPC, allowing communication with external networks.

 3. **Route Table**:

	- Resource Type: aws_route_table
	- Description: Creates a route table to direct traffic from the VPC to the internet via the internet gateway.
	- Route: Allows outbound traffic to all IP addresses (0.0.0.0/0).
 
 4. **Route Table Association**:

	- Resource Type: aws_route_table_association
	- Description: Associates the public route table with the public subnet, enabling instances in the public subnet to access the internet.

 5. **Public Subnet 1**:

	- Resource Type: aws_subnet
	- Description: Creates the first public subnet within the VPC.
	- Properties: Automatically assigns public IPs to instances launched in this subnet, facilitating internet access for those instances.

 6. **Public Subnet 2**:

	- Resource Type: aws_subnet
	- Description: Creates the second public subnet within the VPC.

 7. **Private Subnet**:

	- Resource Type: aws_subnet
	- Description: Creates a private subnet within the VPC
	
 8. **Security Group**:

	- Resource Type: aws_security_group
	- Description: Creates a security group that allows inbound HTTP traffic (port 80) and all outbound traffic, ensuring that web traffic can reach the ECS services.

 9. **ECS Cluster**:

	- Resource Type: aws_ecs_cluster
	- Description: Creates an ECS cluster for managing containerized applications, providing a managed environment for running containers.

 10. **ECS Task Definition**:
 
 	- Resource Type: aws_ecs_task_definition
 	- Description: Defines a Fargate task with specific container configurations.
	- Properties:
		- Family: Defined by the variable task_definition_family.
		- Network Mode: awsvpc, enabling network isolation and control.
		- CPU: 256 units, specifying the CPU resources for the task.
		- Memory: 512 MiB, defining the memory allocation for the task.
		- Container Definition: Defines a single container running an HTTP server with a sample HTML page.

 11. **ECS Service**:
 
	- Resource Type: aws_ecs_service
	- Description: Creates a service for the Fargate task definition, ensuring that the specified number of tasks are running.
	- Properties:
		- Desired Count: 1 (indicates one task should be running).
		- Launch Type: FARGATE, allowing serverless container management.
		- Network Configuration: Uses the public subnets and the defined security group, assigning public IPs to the tasks.

 12. **Application Load Balancer (ALB)**:

	- Resource Type: aws_lb
	- Description: Creates an Application Load Balancer for routing HTTP traffic to the ECS service.
 
 13. **Target Group**:

	- Resource Type: aws_lb_target_group
	- Description: Defines a target group for the ALB to direct traffic to the ECS service.
 
 14. ### EFS (Elastic File System)

	- An **EFS file system** is created for persistent storage.
	- An **EFS mount target** is created in the first public subnet, associated with the ECS security group.
	- The EFS volume is mounted to the Fargate tasks, allowing containers to access the file system for data storage and sharing.
 
## Usage

 1. **Clone the Repository: Clone the repository containing the Terraform configuration.**
 2. **Navigate to the Directory: Open your terminal and navigate to the directory containing the Terraform files.**
 3. **Initialize Terraform: Run the command:**
 
 	```bash
 	terraform init
 	```
 	
 4. **Plan the Deployment: Check what resources will be created by running:**
	
	```bash 
	terraform plan
	```
	
 5. **Apply the Configuration: Deploy the infrastructure by running:**
	
	```bash
	terraform apply
	```
	
 6. **Verify Resources: Once applied, verify the created resources in the AWS Management Console.**

## Notes
 - Ensure your AWS credentials are configured properly for Terraform to authenticate and create resources in your account.
 - Review and update the security group rules as needed based on your application requirements.

## Cleanup

 - To remove all the created resources, run:
	
 ```bash
 terraform destroy
 ```


