###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

# Data source process to fetch all the existing value from IBM cloud environment

data "ibm_is_region" "primary_smc_region" {
  name = local.primary_smc_region_name
}

data "ibm_is_region" "secondary_smc_region" {
  name = length(var.smc_zone) > 1 ? local.secondary_smc_region_name  : ""
}

data "ibm_is_region" "secondary_candidate_smc_region" {
  name = length(var.smc_zone) > 2 ? local.secondary_candidate_smc_region_name : ""
}

data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

data "ibm_is_instance_profile" "bastion" {
  name = var.bastion_host_instance_type
}

data "ibm_is_instance_profile" "smc_profile" {
  name = var.smc_host_instance_type
}