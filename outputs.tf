###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

output "primary_region_name" {
  value       = data.ibm_is_region.primary_smc_region.name
  description = "Region for Primary SMC host"
}

output "secondary_region_name" {
  value       = (local.secondary_smc_region_name != null ? data.ibm_is_region.secondary_smc_region.name : null)
  description = "Region for Secondary SMC host"
}

output "secondary_candidate_region_name" {
  value       = (local.secondary_candidate_smc_region_name != null ? data.ibm_is_region.secondary_candidate_smc_region.name : null)
  description = "Region for Secondary-Candidate SMC host"
}

output "primary_host_name" {
  value       = length(var.smc_zone) > 0 ? "${var.cluster_prefix}-primary.${var.dns_domain}" : null
  description = "Primary SMC host domain name"
}

output "secondary_host_name" {
  value       = length(var.smc_zone) > 1 ? "${var.cluster_prefix}-secondary.${var.dns_domain}" : null
  description = "Secondary SMC host domain name"
}

output "secondary_candidate_host_name" {
  value       = length(var.smc_zone) > 2 ? "${var.cluster_prefix}-secondary-candidate.${var.dns_domain}" : null
  description = "Secondary-Candidate SMC host domain name"
}

output "primary_dns_server_ip" {
  value = module.primary_dns_custom_resolver.dns_server_ip
  description = "SMC primary domain name server IP"
}

output "secondary_dns_server_ip" {
  value = (local.secondary_smc_region_name != null ? module.secondary_dns_custom_resolver[0].dns_server_ip : null)
  description = "SMC secondary domain name server IP"
}

output "secondary_candidate_dns_server_ip" {
  value = (local.secondary_candidate_smc_region_name != null ? module.secondary_candidate_dns_custom_resolver[0].dns_server_ip : null)
  description = "SMC secondary_candidate domain name server IP"
}

output "smc_web_console" {
  value       = "https://localhost:8443/platform"
  description = "SMC web console will be available with this url, after login with ssh command with tunneling"
}

output "ssh_command" {
  value       = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -L 8443:localhost:8443 -J ubuntu@${module.bastion_attach_fip.floating_ip_addr} root@${module.primary_smc.vsi_private_ip}"
  description = "SSH command that can be used to login to bastion host to manage the cluster, also enables webconsole with tunneling."
}