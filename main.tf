// Creating a VPC (Virtual Private Cloud)
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr  // Specify the CIDR block for the VPC


  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "MainVPC"  // Tag for identification
  }
}

// Creating an internet gateway to provide internet access to the VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  // Attach the internet gateway to the VPC

  tags = {
    Name = "MainInternetGateway"  // Tag for identification
  }
}

// Creating a route table to define a route for internet access 
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id  // Associate the route table with the VPC

  // Define a route to direct traffic to the internet gateway
  route {
    cidr_block = "0.0.0.0/0"  // This route applies to all IP addresses
    gateway_id = aws_internet_gateway.main.id  // Use the internet gateway for this route
  }

  tags = {
    Name = "PublicRouteTable"  // Tag for identification
  }
}

// Creating the first public subnet
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main.id  // Associate the subnet with the VPC
  cidr_block        = var.public_subnet_cidr_1  // Specify the CIDR block for the first public subnet
  availability_zone = "${var.aws_region}a"  // Define the availability zone for the subnet
  map_public_ip_on_launch = true  // Automatically assign public IPs to instances launched in this subnet

  tags = {
    Name = "PublicSubnet1"  // Tag for identification
  }
}

// Creating the second public subnet
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main.id  // Associate the subnet with the VPC
  cidr_block        = var.public_subnet_cidr_2  // Specify the CIDR block for the second public subnet
  availability_zone = "${var.aws_region}b"  // Define the availability zone for the subnet
  map_public_ip_on_launch = true  // Automatically assign public IPs to instances launched in this subnet

  tags = {
    Name = "PublicSubnet2"  // Tag for identification
  }
}

// Associating the public route table with the public subnets
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}


// Creating the private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id  // Associate the subnet with the VPC
  cidr_block        = var.private_subnet_cidr  // Specify the CIDR block for the private subnet
  availability_zone = "${var.aws_region}a"  // Define the availability zone for the subnet

  tags = {
    Name = "PrivateSubnet"  // Tag for identification
  }
}

// Creating the security group with HTTP inbound rule and one outbound rule for ECS
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id  // Associate the security group with the VPC

  // Inbound rule to allow HTTP traffic
  ingress {
    from_port   = 80  // Allow traffic on port 80
    to_port     = 80  // Allow traffic on port 80
    protocol    = "tcp"  // Use TCP protocol
    cidr_blocks = ["0.0.0.0/0"]  // Allow traffic from all IP addresses
  }

  // Inboud rule to allow NFS Port access for the EFS volume 
  ingress {
  from_port   = 2049
  to_port     = 2049
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  // Allow traffic from all IP addresses
  }


  // Outbound rule to allow all outbound traffic
  egress {
    from_port   = 0  // Allow all ports
    to_port     = 0  // Allow all ports
    protocol    = "-1"  // Allow all protocols
    cidr_blocks = ["0.0.0.0/0"]  // Allow traffic to all IP addresses
  }

  egress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  // Allow outbound traffic to all IP addresses (or restrict to specific IPs if needed)
  }


  tags = {
    Name = "ECS_Security_Group"  // Tag for identification
  }
}

// Creating the security group for the Application Load Balancer
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id  // Associate the security group with the VPC

  // Inbound rule to allow HTTP traffic from the internet
  ingress {
    from_port   = 80  // Allow traffic on port 80
    to_port     = 80  // Allow traffic on port 80
    protocol    = "tcp"  // Use TCP protocol
    cidr_blocks = ["0.0.0.0/0"]  // Allow traffic from all IP addresses
  }

  // Outbound rule to allow all outbound traffic
  egress {
    from_port   = 0  // Allow all ports
    to_port     = 0  // Allow all ports
    protocol    = "-1"  // Allow all protocols
    cidr_blocks = ["0.0.0.0/0"]  // Allow traffic to all IP addresses
  }

  tags = {
    Name = "ALB_Security_Group"  // Tag for identification
  }
}

// Creating an Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = var.alb_name  // Use variable for ALB name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  // Remove the Environment tag to avoid the tag policy error
  tags = {
    Name = var.alb_name  // Added name tag for identification
  }
}

// Creating a target group for the Application Load Balancer with target type "ip"
resource "aws_lb_target_group" "app_tg" {
  name     = var.target_group_name  // Use variable for target group name
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"  // Specify the target type as "ip" for Fargate compatibility

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold  = 2
    unhealthy_threshold = 2
  }
}


// Creating a listener for the Application Load Balancer
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

// Creating an ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name  // Specify the name of the ECS cluster
}


//////////////////////////////////////////////////////// Code Mounting the EFS onto task denition 1 named fargate_task ///////////////////////////////////////////////////////////

// Creating an EFS file system
resource "aws_efs_file_system" "efs" {
  creation_token = "${var.service_name}-efs"  // Unique token for EFS creation
  performance_mode = "generalPurpose"  // Performance mode for EFS

  tags = {
    Name = "${var.service_name}-efs"  // Tag for identification
  }
}

// Creating a mount target for the EFS file system in the public subnet
resource "aws_efs_mount_target" "efs_mount_target_1" {
  file_system_id = aws_efs_file_system.efs.id  // Associate the EFS mount target with the EFS
  subnet_id      = aws_subnet.public_subnet_1.id  // Specify the subnet for the mount target

  security_groups = [aws_security_group.ecs_sg.id]  // Associate the security group with the mount target
}





// Creating a task definition for the Fargate task to run on fargate_service-1 having the EFS volume Mounted
resource "aws_ecs_task_definition" "fargate_task" {
  family                   = var.task_definition_family  // Specify the family name for the task definition
  requires_compatibilities = ["FARGATE"]  // Define compatibility with Fargate
  network_mode            = "awsvpc"  // Use awsvpc network mode for task
  cpu                     = "256"  // Specify the CPU units for the task
  memory                  = "512"  // Specify the memory for the task

  // Volume definitions for the task
  volume {
    name = "efs-volume"  // Define the name for the volume
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.efs.id  // Associate the EFS file system with the volume
      root_directory = "/"  // Specify the root directory for the EFS volume
    }
  }

  // Container definitions for the task
  container_definitions = jsonencode([
    {
      name  = "fargate-app"  // Specify the name for the container
      image = "public.ecr.aws/docker/library/httpd:latest"  // Specify the image for the container
      portMappings = [
        {
          containerPort = 80  // Specify the port the container listens on
          hostPort      = 80  // Specify the host port for the mapping
          protocol      = "tcp"  // Use TCP protocol
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "efs-volume"  // Reference the EFS volume defined earlier
          containerPath = "/mnt/efs"  // Specify the path in the container where the EFS volume will be mounted
        }
      ]
    }
  ])
}










// Creating another task definition for the Fargate task ///////////////////////////////////////////////////////////////////////////////////////////////
resource "aws_ecs_task_definition" "fargate_task_1" {
  family                   = "${var.task_definition_family}-1"  // Specify the family name for the task definition
  requires_compatibilities = ["FARGATE"]  // Define compatibility with Fargate
  network_mode            = "awsvpc"  // Use awsvpc network mode for task
  cpu                     = "256"  // Specify the CPU units for the task
  memory                  = "512"  // Specify the memory for the task

  // Container definitions for the task
  container_definitions = jsonencode([
    {
      name         = "fargate-app-1"  // Name of the container
      image        = "public.ecr.aws/docker/library/httpd:latest"  // Container image to use
      portMappings = [
        {
          containerPort = 80  // Port the container listens on
          hostPort      = 80  // Port on the host to map to
          protocol      = "tcp"  // Protocol for the port mapping
        }
      ],
      essential     = true,  // Mark the container as essential
      entryPoint    = [
        "sh",  // Entry point for the container
        "-c"  // Execute the command provided
      ],
      command       = [
        "/bin/sh -c \"echo '<html> <head> <title>Amazon ECS Sample App</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App 2</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p> </div></body></html>' > /usr/local/apache2/htdocs/index.html && httpd-foreground\""
      ]
    }
  ])
}



// Creating an ECS service for the Fargate task in the first public subnet
resource "aws_ecs_service" "fargate_service_1" {
  name            = "${var.service_name}-1"  // Append a suffix to the service name
  cluster         = aws_ecs_cluster.ecs_cluster.id  // Associate the service with the ECS cluster
  task_definition = aws_ecs_task_definition.fargate_task.arn  // Specify the task definition for the service
  desired_count   = 1  // Specify the number of task instances to run
  launch_type     = "FARGATE"  // Define the launch type for the service

  // Network configuration for the service
  network_configuration {
    subnets          = [aws_subnet.public_subnet_1.id]  // Specify the subnet for the service
    security_groups  = [aws_security_group.ecs_sg.id]  // Specify the security group for the service
    assign_public_ip = true  // Assign a public IP address to the service
  }

  // Load balancer configuration for the service
  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn  // Specify the target group for the load balancer
    container_name   = "fargate-app"  // Specify the container name
    container_port   = 80  // Specify the container port
  }

  depends_on = [aws_lb_listener.http_listener]  // Ensure the listener is created before the service
}




// Creating the second ec2 service for task definition fargate_task_1

resource "aws_ecs_service" "fargate_service_2" {
  name            = "${var.service_name}-2"  // Append a suffix to the service name
  cluster         = aws_ecs_cluster.ecs_cluster.id  // Associate the service with the ECS cluster
  task_definition = aws_ecs_task_definition.fargate_task_1.arn  // Specify the task definition for the service
  desired_count   = 1  // Specify the number of task instances to run
  launch_type     = "FARGATE"  // Define the launch type for the service

  // Network configuration for the service
  network_configuration {
    subnets          = [aws_subnet.public_subnet_2.id]  // Specify the subnet for the service
    security_groups  = [aws_security_group.ecs_sg.id]  // Specify the security group for the service
    assign_public_ip = true  // Assign a public IP address to the service
  }

  // Load balancer configuration for the service
  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn  // Specify the target group for the load balancer
    container_name   = "fargate-app-1"  // Specify the container name
    container_port   = 80  // Specify the container port
  }

  depends_on = [aws_lb_listener.http_listener]  // Ensure the listener is created before the service
}

