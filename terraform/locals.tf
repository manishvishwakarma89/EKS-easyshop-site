locals {
    region="us-west-2"
    name="msstech-eks-cluster"
    vpc_cidr="10.0.0.0/16"
    azs=["us-west-2a","us-west-2b"]
    public_subnets=["10.0.1.0/24","10.0.2.0/24"]
    private_subnets=["10.0.101.0/24","10.0.102.0/24"]
    intra_subnets=["10.0.5.0/24","10.0.6.0/24"]
    env="dev"
    
}