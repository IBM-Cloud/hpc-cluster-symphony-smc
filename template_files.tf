###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

# Templete file renders template from template string to process user_data in IBM cloud environment

locals {
  script_map = {
    "primary" = file("${path.module}/scripts/user_data_input_primary.tpl")
  }
   primary_template_file = lookup(local.script_map, "primary")
}

data "template_file" "metadata_startup_script" {
  template = <<EOF
#!/usr/bin/env bash
if grep -q "Red Hat" /etc/os-release
then
    USER=vpcuser
    yum --security update -y
elif grep -q "Ubuntu" /etc/os-release
then
    USER=ubuntu
fi
sed -i -e "s/^/no-port-forwarding,no-agent-forwarding,no-X11-forwarding,command=\"echo \'Please login as the user \\\\\"$USER\\\\\" rather than the user \\\\\"root\\\\\".\';echo;sleep 10; exit 142\" /" /root/.ssh/authorized_keys
echo "${local.public_key_content}" >> /home/$USER/.ssh/authorized_keys
echo "StrictHostKeyChecking no" >> /home/$USER/.ssh/config
EOF
}

data "local_file" "ansible_smc_data_syn" {
    filename = "${path.module}/scripts/data_sync.yml"
}

data "template_file" "primary_user_data" {
  template = local.primary_template_file
  vars = {
    cluster_id           = var.cluster_id
    smc_host_role        = "primary"
    cluster_cidr         = module.primary_subnet.ipv4_cidr_block
    cluster_prefix       = var.cluster_prefix
    ansible_smc_data_syn = data.local_file.ansible_smc_data_syn.content
    ssh_private_key      = local.private_key_content
    ssh_public_key       = local.public_key_content
    dns_domain           = var.dns_domain
    smc_zone_length      = length(var.smc_zone)
  }
}

data "template_file" "secondary_user_data" {
  count     = length(var.smc_zone) > 1 ? 1 : 0
  template  = local.primary_template_file
  vars = {
    cluster_id           = var.cluster_id
    smc_host_role        = "secondary"
    cluster_cidr         = module.secondary_subnet.*.ipv4_cidr_block[0]
    cluster_prefix       = var.cluster_prefix
    ansible_smc_data_syn = data.local_file.ansible_smc_data_syn.content
    ssh_private_key      = local.private_key_content
    ssh_public_key       = local.public_key_content
    dns_domain           = var.dns_domain
    smc_zone_length      = length(var.smc_zone)
  }
}

data "template_file" "secondary_candidate_user_data" {
  count     = length(var.smc_zone) > 2 ? 1 : 0
  template  = local.primary_template_file
  vars = {
    cluster_id           = var.cluster_id
    smc_host_role        = "secondary_candidate"
    cluster_cidr         = module.secondary_candidate_subnet.*.ipv4_cidr_block[0]
    cluster_prefix       = var.cluster_prefix
    ansible_smc_data_syn = data.local_file.ansible_smc_data_syn.content
    ssh_private_key      = local.private_key_content
    ssh_public_key       = local.public_key_content
    dns_domain           = var.dns_domain
    smc_zone_length      = length(var.smc_zone)
  }
}