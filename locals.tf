###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    Note : IBM SMC cloud deploys VPC creation in the below region format.
        region_1 			 region_2				   region_3
    Primary_smc_region  Secondary_smc_region secondary_candaidate_smc_region
*/

locals {
  tags = ["HPCC", var.cluster_prefix, "Multicluster"]

  // Disk configure
  volume_profile  = "general-purpose"
  volume_capacity = 10

  // Stock_image used for login/bastion host
  stock_image_name = "ibm-ubuntu-22-04-1-minimal-amd64-4"

  // From var.smc_zone split region
  regions                        = [for s in var.smc_zone : join("-", slice(split("-", s), 0, 2))]
  // Distinct function is used to remove any of the duplicates regions from the "local.regions"
  smc_region                     = distinct(local.regions)

  // Assign smc_region based on length of local.regions
  primary_smc_region             = length(local.regions) > 0 ? local.regions[0] : null
  secondary_smc_region           = length(local.regions) > 1 ? local.regions[1] : null
  secondary_candidate_smc_region = length(local.regions) > 2 ? local.regions[2] : null

  primary_smc_region_name             = local.primary_smc_region
  // While comparing secondary and primary, if the value is equal then variable local.secondary_smc_region_name will be null. This is useful in restricting duplicate VPC creation in same region
  secondary_smc_region_name           = (local.secondary_smc_region == local.primary_smc_region ? null : 
                                         local.secondary_smc_region)
  // While comparing secondary_candidate_smc_region is equal to secondary_smc_region or primary_smc_region then variable local.secondary_candidate_smc_region_name will be null, it will restrict during vpc creation in same region
  secondary_candidate_smc_region_name = (local.secondary_candidate_smc_region == local.secondary_smc_region || 
                                         local.secondary_candidate_smc_region == local.primary_smc_region ? null : 
                                         local.secondary_candidate_smc_region)

  // Assign smc_zone based on length of var.smc_zone
  primary_smc_zone             = length(var.smc_zone) > 0 ? var.smc_zone[0] : null
  secondary_smc_zone           = length(var.smc_zone) > 1 ? var.smc_zone[1] : null
  secondary_candidate_smc_zone = length(var.smc_zone) > 2 ? var.smc_zone[2] : null

  // If a value for var.lone_vpc_region exists, assign the respective index value for that specific region and if there is no value present then the value return with null
  lone_1_region   = (var.lone_vpc_region != null ? length(var.lone_vpc_region) > 0 ? var.lone_vpc_region[0] : null : null)
  lone_2_region   = (var.lone_vpc_region != null ? length(var.lone_vpc_region) > 1 ? var.lone_vpc_region[1] : null : null)
  lone_3_region   = (var.lone_vpc_region != null ? length(var.lone_vpc_region) > 2 ? var.lone_vpc_region[2] : null : null)

  // If a value for var.lone_vpc_name exists, assign the respective index value for that specific region and if there is no value present then the value return with null
  lone_1_vpc    = (var.lone_vpc_name != null ? length(var.lone_vpc_name) > 0 ? var.lone_vpc_name[0] : null : null)
  lone_2_vpc    = (var.lone_vpc_name != null ? length(var.lone_vpc_name) > 1 ? var.lone_vpc_name[1] : null : null)
  lone_3_vpc    = (var.lone_vpc_name != null ? length(var.lone_vpc_name) > 2 ? var.lone_vpc_name[2] : null : null)

  // Check whether an entry is found in the mapping file for the given SMC image
  smc_image_mapping_entry_found        = contains(keys(local.image_region_map), var.smc_image_name) ? true : false
  image_map_lookup                     = local.smc_image_mapping_entry_found ? lookup(local.image_region_map, var.smc_image_name) : null
  // If map_entry found, get the respective region image_id from image-map.tf
  new_primary_smc_image_id             = (local.smc_image_mapping_entry_found && local.primary_smc_region != null ? lookup(local.image_map_lookup, local.primary_smc_region_name) : "Image not found with the given name")
  new_secondary_smc_image_id           = (local.smc_image_mapping_entry_found && local.secondary_smc_region !=null ? lookup(local.image_map_lookup, local.secondary_smc_region) : "Image not found with the given name")
  new_secondary_candidate_smc_image_id = (local.smc_image_mapping_entry_found && local.secondary_candidate_smc_region !=null ? lookup(local.image_map_lookup, local.secondary_candidate_smc_region) : "Image not found with the given name")
  
  // SMC host cidr_block
  primary_smc_host_ip             = [cidrhost(var.primary_cidr_block, 1 + 4)]
  secondary_smc_host_ip           = [cidrhost(var.secondary_cidr_block, 1 + 4)]
  secondary_candidate_smc_host_ip = [cidrhost(var.secondary_candidate_cidr_block, 1 + 4)]

  // SMC host ipv4 cidr_block
  cidr_block_sg_allow = concat(
    [var.primary_cidr_block, var.secondary_cidr_block, var.secondary_candidate_cidr_block],
    var.login_cidr_block,
    var.lone_symphony_cidr_block != null ? var.lone_symphony_cidr_block : [])
  
  // Create private and public key to passwordless ssh between SMC host
  private_key_content = tostring(module.proxy_ssh_keys.private_key_content)
  public_key_content  = tostring(module.proxy_ssh_keys.public_key_content)

  // SMC host vpc_id
  primary_vpc_id             = module.primary_vpc.*.vpc_id
  // Compare secondary_smc_region_name not null, assign secondary_vpc_id. If not assign to primary_vpc_id
  secondary_vpc_id           = (local.secondary_smc_region_name != null ? module.secondary_vpc.*.vpc_id : 
                                module.primary_vpc.*.vpc_id)
  // Compare secondary_candiate_smc_region_name not null, will get secondary_vpc_id. If not assign to primary_vpc_id
  secondary_candidate_vpc_id = (local.secondary_candidate_smc_region_name != null ? module.secondary_candidate_vpc.*.vpc_id : 
                                local.secondary_candidate_smc_region == local.primary_smc_region ? module.primary_vpc.*.vpc_id :
                                local.secondary_candidate_smc_region == local.secondary_smc_region ? module.secondary_vpc.*.vpc_id : [])
                                
  // If lone_vpc_name exists, using data "ibm_is_vpc" to fetch vpc_crn
  lone_vpc_crn               = concat(module.lone_1_existing_vpc.*.existing_vpc_crn, 
                                       module.lone_2_existing_vpc.*.existing_vpc_crn, 
                                       module.lone_3_existing_vpc.*.existing_vpc_crn)

  // If lone_vpc_name exists, using data "ibm_is_vpc_address_prefixes" to fetch vpc_cidr
  lone_vpc_cidr              = concat(module.lone_1_existing_vpc.*.existing_vpc_cidr, 
                                       module.lone_2_existing_vpc.*.existing_vpc_cidr, 
                                       module.lone_3_existing_vpc.*.existing_vpc_cidr)

  // SMC host vpc_crn for transit_gateway creation
  primary_vpc_crn             = module.primary_vpc.*.vpc_crn
  // Compare secondary_smc_region_name not null, assign secondary_vpc_crn. If not assign to primary_vpc_crn
  secondary_vpc_crn           = (local.secondary_smc_region_name != null ? module.secondary_vpc.*.vpc_crn : 
                                 local.secondary_smc_region == local.primary_smc_region ? [] : module.primary_vpc.*.vpc_crn)
  // Compare secondary_candiate_smc_region_name not null, assign secondary_candidate_vpc_crn. If not secondary_candidate_smc_region equal to primary_region or secondary_region assign to primary_vpc_crn or secondary_vpc_crn respectively.
  secondary_candidate_vpc_crn = (local.secondary_candidate_smc_region_name != null ? module.secondary_candidate_vpc.*.vpc_crn : 
                                 local.secondary_candidate_smc_region == local.primary_smc_region ? module.primary_vpc.*.vpc_crn :
                                 local.secondary_candidate_smc_region == local.secondary_smc_region ? module.secondary_vpc.*.vpc_crn : [])
  // Concat all SMC host vpc_crn
  smc_vpc_crn                 = concat(local.primary_vpc_crn, 
                                       local.secondary_vpc_crn, 
                                       local.secondary_candidate_vpc_crn)

  // SMC host public_gateway_id for subnet creation
  /*
    Note : Public_gateway creation is not supported if there is already an public_gateway assigned for a zone in the same region.
  */
  primary_public_gw_id             = module.primary_public_gw.*.public_gw_id[0]
  // If the value provided for primary_smc_zone and secondary_smc_zone are equal, assign the public gateway of primary zone. If the values are different assign the public gateway created for secondary zone
  secondary_public_gw_id           = (local.secondary_smc_zone != null ? 
                                        (local.secondary_smc_zone == local.primary_smc_zone ? module.primary_public_gw.*.public_gw_id[0] : 
                                         module.secondary_public_gw.*.public_gw_id[0]) : [])
  // If the value provided for secondary_candidate_zone is equal to primary_smc_zone or secondary_smc_zone, assign the public gateway of primary_zone or secondary_zone respectively. If the values are different assign the public gateway created for secondary_candidate zone
  secondary_candidate_public_gw_id = (local.secondary_candidate_smc_zone != null ? 
                                        (local.secondary_candidate_smc_zone == local.primary_smc_zone ? module.primary_public_gw.*.public_gw_id[0] :
                                        local.secondary_candidate_smc_zone == local.secondary_smc_zone ? module.secondary_public_gw.*.public_gw_id[0] : 
                                         module.secondary_candidate_public_gw.*.public_gw_id[0]) : [])

  // SMC host security_group_id
  primary_security_group_id             = [module.primary_security_group.*.sec_group_id]
  // If the value provided for secondary_smc_region and primary_smc_region are equal, assign the security group of primary_security_group_id. If the values are different assign the security_group created for secondary_security_group_id
  secondary_security_group_id           = (local.secondary_smc_region != null ? 
                                            (local.secondary_smc_region == local.primary_smc_region ? [module.primary_security_group.*.sec_group_id] : 
                                             [module.secondary_security_group.*.sec_group_id]) : [])
  // If secondary_candidate_region_name not null, assign secondary_candidate_security_group_id. If not compare with secondary and primary security_group_id assign accordingly, will restrict duplicate security_group creation
  secondary_candidate_security_group_id = (local.secondary_candidate_smc_region != null ? 
                                            (local.secondary_candidate_smc_region == local.primary_smc_region ? [module.primary_security_group.*.sec_group_id] :
                                            (local.secondary_candidate_smc_region == local.secondary_smc_region ? [module.secondary_security_group.*.sec_group_id] : 
                                             [module.secondary_candidate_security_group.*.sec_group_id])) : [])

  // SMC host ssh_key_id
  primary_ssh_key_id             = module.primary_ssh_key.*.ssh_key_id_list[0]
  // Compare secondary_smc_region not null, assign secondary_ssh_key_id. If not assign to primary_ssh_key_id
  secondary_ssh_key_id           = (local.secondary_smc_region != null ? 
                                    (local.secondary_smc_region == local.primary_smc_region ? module.primary_ssh_key.*.ssh_key_id_list[0] : 
                                     module.secondary_ssh_key.*.ssh_key_id_list[0]) : [])
  // Compare secondary_candiate_smc_region not null, assign secondary_candidate_ssh_key. If not secondary_candidate_smc_region equal to primary_region or secondary_region assign to primary_ssh_key or secondary_ssh_key respectively.
  secondary_candidate_ssh_key_id = (local.secondary_candidate_smc_region != null ? 
                                    (local.secondary_candidate_smc_region == local.primary_smc_region ? module.primary_ssh_key.*.ssh_key_id_list[0] :
                                    (local.secondary_candidate_smc_region == local.secondary_smc_region ? module.secondary_ssh_key.*.ssh_key_id_list[0] : 
                                     module.secondary_candidate_ssh_key.*.ssh_key_id_list[0])) : [])
}
