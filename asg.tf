#### ASG Module ####

module "asg-ms" { 
  source = "./asg" 

  app                            = var.app
}


#### ASG Resources ####

resource "aws_security_group" "app" {
  name        = "${var.app["name"]}-${var.app["env"]}-sg-app"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = "0"
    to_port     = "65535"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app["name"]}-${var.app["env"]}-sg-app"
  }
}

resource "aws_autoscaling_group" "app" {
  name                      = "${var.app["name"]}-${var.app["env"]}-ec2"
  vpc_zone_identifier       = ["${aws_subnet.private[0].id}", "${aws_subnet.private[1].id}"] 
  launch_configuration      = "${aws_launch_configuration.app.name}"
  max_size                  = 10
  min_size                  = 0
  desired_capacity          = "1"
  health_check_grace_period = 30
  health_check_type         = "EC2"
  force_delete              = true

  tag {
    key = "Name"
    value = "${var.app["name"]}-${var.app["env"]}-ec2-${var.node_suffix}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "app" {
  name_prefix          = "${var.app["name"]}-${var.app["env"]}-lc"
  image_id             = "ami-0dfa0bf531cde9048"
  security_groups      = ["${aws_security_group.app.id}", "${aws_security_group.main.id}"]
  instance_type        = "m5.large"
  key_name             = "Test-Key"

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type = "standard"
    volume_size = "40"
  }
}
