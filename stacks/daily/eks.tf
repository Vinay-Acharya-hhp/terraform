module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = local.vpc_id
  subnet_ids = values(local.private_subnet_ids)

  # Same as your cluster.yaml: public API endpoint, no Auto Mode
  cluster_endpoint_public_access = true

  # Creates the OIDC provider (your withOIDC: true)
  enable_irsa = true

  # The identity running Terraform becomes cluster admin
  enable_cluster_creator_admin_permissions = true

  # Same add-ons eksctl installs by default
  cluster_addons = {
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    kube-proxy = { most_recent = true }
    coredns    = { most_recent = true }
  }

  eks_managed_node_groups = {
    ng-private = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.node_instance_type]

      min_size     = var.node_count
      max_size     = var.node_count
      desired_size = var.node_count
    }
  }

  # Nodes need the NAT route to pull images and reach AWS APIs
  depends_on = [aws_route.private_nat]
}