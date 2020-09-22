resource "aws_efs_file_system" "efs_provisioner" {
  creation_token   = var.efs_name
  performance_mode = var.efs_performance_mode
  encrypted        = "true"

  tags = merge(map("Name", var.efs_name), var.tags)

}

resource "aws_efs_mount_target" "efs_provisioner" {
  count           = length(var.private_subnets)
  file_system_id  = aws_efs_file_system.efs_provisioner.id
  subnet_id       = element(module.vpc.private_subnets, count.index)
  security_groups = [aws_security_group.ingress_efs.id]
}

resource "aws_security_group" "ingress_efs" {
  name        = "ingress-${var.efs_name}-sg"
  description = "Allow NFS traffic."
  vpc_id      = module.vpc.vpc_id

  // NFS
  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"

    security_groups = [aws_security_group.worker_group_mgmt_one.id, aws_security_group.worker_group_mgmt_two.id,aws_security_group.all_worker_mgmt.id]
  }

  // Terraform removes the default rule
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.worker_group_mgmt_one.id, aws_security_group.worker_group_mgmt_two.id,aws_security_group.all_worker_mgmt.id]
  }

  tags = merge(map("Name", var.efs_name), var.tags)
}

output "efs_provisoner_fsid" {
  value = aws_efs_file_system.efs_provisioner.id
}