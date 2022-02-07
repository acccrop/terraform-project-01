variable "terraform" {
  type = any
}

variable provider_configs {
  type = map(map(string))
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc" {
  type = object({
    availability_zones = list(string)
    cidr = object({
      vpc             = string
      private_subnets = list(string)
      public_subnets  = list(string)
    })
  })
}

variable "eks" {
  type = object({
    version         = string
    instance_type   = string
    nodes_count_min = number
    nodes_count_max = number
    nodes_disk_size = number
    access = object({
      cidr     = list(string)
      accounts = list(string)
      roles = list(object({
        rolearn  = string
        username = string
        groups   = list(string)
      }))
      users = list(object({
        userarn  = string
        username = string
        groups   = list(string)
      }))

    })
  })
}
