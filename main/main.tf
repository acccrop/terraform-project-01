locals {
  cluster_name = "${var.environment}-eks"
  tags = merge({
    Environment = var.environment
  }, var.tags)
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.47.0"

  name                 = "${var.environment}-vpc"
  cidr                 = var.vpc.cidr.vpc
  azs                  = var.vpc.availability_zones
  private_subnets      = var.vpc.cidr.private_subnets
  public_subnets       = var.vpc.cidr.public_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = merge({
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }, local.tags)

  private_subnet_tags = merge({
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }, local.tags)
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = var.eks.version
  subnets         = module.vpc.private_subnets

  tags = local.tags

  vpc_id = module.vpc.vpc_id

  node_groups = {
    default = {
      desired_capacity = var.eks.nodes_count_min
      max_capacity     = var.eks.nodes_count_max
      min_capacity     = var.eks.nodes_count_min

      instance_types = [var.eks.instance_type]

      k8s_labels = local.tags
    }
  }

  map_roles    = var.eks.access.roles
  map_users    = var.eks.access.users
  map_accounts = var.eks.access.accounts

  cluster_endpoint_public_access_cidrs = var.eks.access.cidr
}

