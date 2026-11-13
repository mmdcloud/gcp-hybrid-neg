resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  private_ip                  = var.private_ip
  associate_public_ip_address = var.associate_public_ip_address
  vpc_security_group_ids      = length(var.vpc_security_group_ids) > 0 ? var.vpc_security_group_ids : var.security_groups
  iam_instance_profile        = var.iam_instance_profile != null ? var.iam_instance_profile : var.instance_profile

  user_data                   = var.user_data
  user_data_base64            = var.user_data_base64
  user_data_replace_on_change = var.user_data_replace_on_change

  ebs_optimized     = var.ebs_optimized
  monitoring        = var.monitoring
  source_dest_check = var.source_dest_check

  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior

  # Production IMDSv2 enforcement (Blocks SSRF credential abuse)
  metadata_options {
    http_endpoint               = var.metadata_http_endpoint
    http_tokens                 = var.metadata_http_tokens
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
    instance_metadata_tags      = var.metadata_instance_metadata_tags
  }

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    iops                  = contains(["gp3", "io1", "io2"], var.root_volume_type) ? var.root_iops : null
    throughput            = var.root_volume_type == "gp3" ? var.root_throughput : null
    encrypted             = var.root_encrypted
    kms_key_id            = var.root_kms_key_id
    delete_on_termination = var.root_delete_on_termination

    tags = merge(
      var.tags,
      {
        Name = "${var.name}-root-volume"
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
