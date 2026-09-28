output "vpc_id" {
  value = aws_vpc.main.id
}

output "intra_subnets" {
  value = aws_subnet.intra[*].id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}