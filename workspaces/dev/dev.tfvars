terraform = {
    required_version = ">= 0.13"
    backend = {
        s3 = {
            bucket  = "dev-oip-terraform"
            key     = "dev/terraform.tfstate"
            encrypt = true
            region  = "eu-west-2"
            dynamodb_table = "terraform"
        }
    }
}

provider_configs = {
    aws = {
        region = "eu-west-2"
        profile = "default"
    }
}

environment = "dev"

tags = {
    "ManagedBy" = "Dinuth"
}

vpc = {
    availability_zones = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
    cidr = {
      vpc             = "10.47.0.0/22"
      private_subnets = ["10.47.0.0/24", "10.47.1.0/24", "10.47.2.0/24"]
      public_subnets  = ["10.47.3.0/26", "10.47.3.64/26", "10.47.3.128/26"]
    }
}

eks = {
    version         = "1.17"
    instance_type   = "t3.small"
    nodes_count_min = 5
    nodes_count_max = 10
    nodes_disk_size = 100
    access = {
        cidr = ["185.125.226.42/32"]
        accounts = ["811425764213"]
        roles = [{
            rolearn  = "arn:aws:iam::811425764213:role/Superadmin"
            username = "system:node:roleaccount"
            groups   = ["system:masters"]
        }]
        users = []
    }
}

