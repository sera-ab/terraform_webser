variable "app" {
  type = map
  default = {
    name = "test"
    env  = "dev"
  }
}

variable "availability_zones" {
  type = list
  default = [
    "us-east-1a", 
    "us-east-1b",
  ]
}

variable "region" {
  type = string
  default = "us-east-1"
}

variable "network" {
  type = map
  default = {
    cidr       = "10.0.0.0/16"
    publicAz1  = "10.0.0.0/24"
    publicAz2  = "10.0.4.0/24"
    privateAz1 = "10.0.8.0/24"
    privateAz2 = "10.0.12.0/24"
  }
}
