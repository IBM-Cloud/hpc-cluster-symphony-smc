###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
Infrastructure creation related steps
*/

// This module generate ssh-key for passwordless ssh between SMC host which can be used for ansible
module "proxy_ssh_keys" {
  source  = "./resources/common/generate_sshkey"
  turn_on = true
}

// This module validates whether the provided bastion_image name is present in the appropriate region
module "bastion_image" {
  providers = {
    ibm = ibm.primary
  }
  source     = "./resources/ibmcloud/compute/image_check"
  image_name = local.stock_image_name
}

// This module validates whether the provided image name is present in the primary region
module "primary_smc_image_check" {
  count     = local.smc_image_mapping_entry_found ? 0 : 1
  providers = {
    ibm = ibm.primary
  }
  source     = "./resources/ibmcloud/compute/image_check"
  image_name = var.smc_image_name
}

// This module validates whether the provided image name is present in the secondary region
module "secondary_smc_image_check" {
  count     = local.smc_image_mapping_entry_found ? 0 : 1
  providers = {
    ibm = ibm.secondary
  }
  source     = "./resources/ibmcloud/compute/image_check"
  image_name = var.smc_image_name
}

// This module validates whether the provided image name is present in the secondary_candidate region
module "secondary_candidate_smc_image_check" {
  count     = local.smc_image_mapping_entry_found ? 0 : 1
  providers = {
    ibm = ibm.secondary_candidate
  }
  source     = "./resources/ibmcloud/compute/image_check"
  image_name = var.smc_image_name
}

// This module validate the provided existing_lone_vpc is present in the lone_1_region
module "lone_1_existing_vpc" {
  count     = (local.lone_vpc_validation && 
               var.lone_vpc_name != null && 
               var.lone_vpc_region != null ? length(var.lone_vpc_region) > 0 ? 1 : 0 : 
               0)
  providers = {
    ibm = ibm.lone_1
  }
  source     = "./resources/ibmcloud/compute/existing_vpc"
  existing_vpc_name = local.lone_1_vpc
}

// This module validate the provided existing_lone_vpc is present in the lone_2_region
module "lone_2_existing_vpc" {
  count     = (local.lone_vpc_validation && 
               var.lone_vpc_name != null && 
               var.lone_vpc_region != null ? length(var.lone_vpc_region) > 1 ? 1 : 0 : 
               0)
  providers = {
    ibm = ibm.lone_2
  }
  source     = "./resources/ibmcloud/compute/existing_vpc"
  existing_vpc_name = local.lone_2_vpc
}

// This module validate the provided existing_lone_vpc is present in the lone_3_region
module "lone_3_existing_vpc" {
  count     = (local.lone_vpc_validation && 
               var.lone_vpc_name != null && 
               var.lone_vpc_region != null ? length(var.lone_vpc_region) > 2 ? 1 : 0 : 
               0)
  providers = {
    ibm = ibm.lone_3
  }
  source     = "./resources/ibmcloud/compute/existing_vpc"
  existing_vpc_name = local.lone_3_vpc
}

// This module validate the provided ssh-key exists in primary region
module "primary_ssh_key" {
  count     = local.primary_smc_region != null ? 1 : 0
  providers = {
    ibm = ibm.primary
  }
  source       = "./resources/ibmcloud/compute/ssh_key"
  ssh_key_name = var.ssh_key_name
}

// This module validate the provided ssh-key exists in secondary region
module "secondary_ssh_key" {
  count     = local.secondary_smc_region != null ? 1 : 0
  providers = {
    ibm = ibm.secondary
  }
  source       = "./resources/ibmcloud/compute/ssh_key"
  ssh_key_name = var.ssh_key_name
}

// This module validate the provided ssh-key exists in secondary_candidate region
module "secondary_candidate_ssh_key" {
  count     = local.secondary_candidate_smc_region != null ? 1 : 0
  providers = {
    ibm = ibm.secondary_candidate
  }
  source       = "./resources/ibmcloud/compute/ssh_key"
  ssh_key_name = var.ssh_key_name
}

// This module creates a new Primary_VPC resource
module "primary_vpc" {
  count     = local.primary_smc_region_name != null ? 1 : 0
  providers = {
    ibm = ibm.primary
  }
  source                        = "./resources/ibmcloud/network/vpc"
  vpc_name                      = format("%s-primary-vpc", var.cluster_prefix)
  vpc_address_prefix_management = "manual"
  resource_group_id             = data.ibm_resource_group.resource_group.id
  tags                          = local.tags
}

// This module creates a new Secondary_VPC resource
module "secondary_vpc" {
  count     = local.secondary_smc_region_name != null ? 1 : 0
  providers = {
    ibm = ibm.secondary
  }
  source                        = "./resources/ibmcloud/network/vpc"
  vpc_name                      = format("%s-secondary-vpc", var.cluster_prefix)
  vpc_address_prefix_management = "manual"
  resource_group_id             = data.ibm_resource_group.resource_group.id
  tags                          = local.tags
}

// This module creates a new Secondary_Candidate_VPC resource
module "secondary_candidate_vpc" {
  count     = local.secondary_candidate_smc_region_name != null ? 1 : 0
  providers = {
    ibm = ibm.secondary_candidate
  }
  source                        = "./resources/ibmcloud/network/vpc"
  vpc_name                      = format("%s-secondary-candidate-vpc", var.cluster_prefix)
  vpc_address_prefix_management = "manual"
  resource_group_id             = data.ibm_resource_group.resource_group.id
  tags                          = local.tags
}

// This module creates a login_address_prefix as we are now using custom CIDR range for VPC creation
module "login_address_prefix" {
  providers = {
    ibm = ibm.primary
  }
  source       = "./resources/ibmcloud/network/vpc_address_prefix"
  vpc_id       = local.primary_vpc_id
  address_name = format("%s-addr-login", var.cluster_prefix)
  zone         = local.primary_smc_zone
  cidr_block   = var.login_cidr_block[0]
  depends_on   = [module.primary_vpc]
}

// This module creates a primary_vpc_address_prefix as we are now using custom CIDR range for VPC creation
module "primary_vpc_address_prefix" {
  providers = {
    ibm = ibm.primary
  }
  source       = "./resources/ibmcloud/network/vpc_address_prefix"
  vpc_id       = local.primary_vpc_id
  address_name = format("%s-addr-primary", var.cluster_prefix)
  zone         = local.primary_smc_zone
  cidr_block   = var.primary_cidr_block
  depends_on   = [module.primary_vpc]
}

// This module creates a secondary_vpc_address_prefix as we are now using custom CIDR range for VPC creation
module "secondary_vpc_address_prefix" {
  count = length(var.smc_zone) > 1 ? 1 : 0
  providers = {
    ibm = ibm.secondary
  }
  source       = "./resources/ibmcloud/network/vpc_address_prefix"
  vpc_id       = local.secondary_vpc_id
  address_name = format("%s-addr-secondary", var.cluster_prefix)
  zone         = local.secondary_smc_zone
  cidr_block   = var.secondary_cidr_block
  depends_on   = [module.secondary_vpc]
}

// This module creates a secondary_candidate_vpc_address_prefix as we are now using custom CIDR range for VPC creation
module "secondary_candidate_vpc_address_prefix" {
  count     = length(var.smc_zone) > 2 ? 1 : 0
  providers = {
    ibm = ibm.secondary_candidate
  }
  source       = "./resources/ibmcloud/network/vpc_address_prefix"
  vpc_id       = local.secondary_candidate_vpc_id
  address_name = format("%s-addr-secondary-candidate", var.cluster_prefix)
  zone         = local.secondary_candidate_smc_zone
  cidr_block   = var.secondary_candidate_cidr_block
  depends_on   = [module.secondary_candidate_vpc]
}

// This module creates transit_gateway for the connection between lone and SMC hosts
module "transit_gw" {
  source              = "./resources/ibmcloud/network/transit_gw"
  transit_gw_name     = format("%s-transit_gw", var.cluster_prefix)
  resource_group_id   = data.ibm_resource_group.resource_group.id
  transit_gw_location = local.primary_smc_region_name
  smc_region          = local.smc_region
  tags                = local.tags
  smc_vpc_crn         = local.smc_vpc_crn
  lone_vpc_crn        = local.lone_vpc_crn
  depends_on          = [module.primary_vpc, 
                         module.secondary_vpc, 
                         module.secondary_candidate_vpc]
}

// This module creates public_gateway in priamry_region
module "primary_public_gw" {
  count     = length(var.smc_zone) > 0 ? 1 : 0
  providers = {
    ibm = ibm.primary
  }
  source            = "./resources/ibmcloud/network/public_gw"
  public_gw_name    = format("%s-primary-gw", var.cluster_prefix)
  resource_group_id = data.ibm_resource_group.resource_group.id
  vpc_id            = local.primary_vpc_id
  zones             = local.primary_smc_zone
  tags              = local.tags
  depends_on        = [module.transit_gw, 
                       module.primary_vpc]
}

// This module creates public_gateway in secondary_region
module "secondary_public_gw" {
  count     = length(var.smc_zone) > 1 ? 1 : 0
  providers = {
    ibm = ibm.secondary
  }
  source            = "./resources/ibmcloud/network/public_gw"
  public_gw_name    = format("%s-secondary-gw", var.cluster_prefix)
  resource_group_id = data.ibm_resource_group.resource_group.id
  vpc_id            = local.secondary_vpc_id
  zones             = (local.secondary_smc_zone == local.primary_smc_zone ? null : 
                       local.secondary_smc_zone)
  tags              = local.tags
  depends_on        = [module.transit_gw, 
                       module.secondary_vpc]
}

// This module creates public_gateway in secondary_candidate_region
module "secondary_candidate_public_gw" {
  count     = length(var.smc_zone) > 2 ? 1 : 0
  providers = {
    ibm = ibm.secondary_candidate
  }
  source            = "./resources/ibmcloud/network/public_gw"
  public_gw_name    = format("%s-secondary-candidate-gw", var.cluster_prefix)
  resource_group_id = data.ibm_resource_group.resource_group.id
  vpc_id            = local.secondary_candidate_vpc_id
  zones             = (local.secondary_candidate_smc_zone == local.secondary_smc_zone || 
                       local.secondary_candidate_smc_zone == local.primary_smc_zone ? null : 
                       local.secondary_candidate_smc_zone)
  tags              = local.tags
  depends_on        = [module.transit_gw, 
                       module.secondary_candidate_vpc]
}

// This module is used to create subnet, which is used to create both login node. The subnet CIDR range is passed manually based on the user input from variable file
module "login_subnet" {
  providers = {
    ibm = ibm.primary
  }
  source            = "./resources/ibmcloud/network/login_subnet"
  vpc_id            = local.primary_vpc_id
  resource_group_id = data.ibm_resource_group.resource_group.id
  zones             = local.primary_smc_zone
  login_subnet_name = format("%s-login-subnet", var.cluster_prefix)
  subnet_cidr_block = var.login_cidr_block[0]
  tags              = local.tags
  depends_on        = [module.primary_vpc, 
                       module.login_address_prefix]
}

// This module is used to create subnet, which is used to create primary_smc. The subnet CIDR range is passed manually based on the user input from variable file
module "primary_subnet" {
  providers = {
    ibm = ibm.primary
  }
  source            = "./resources/ibmcloud/network/subnet"
  vpc_id            = local.primary_vpc_id
  resource_group_id = data.ibm_resource_group.resource_group.id
  zones             = local.primary_smc_zone
  subnet_name       = format("%s-primary-subnet", var.cluster_prefix)
  subnet_cidr_block = var.primary_cidr_block
  public_gateway    = local.primary_public_gw_id
  tags              = local.tags
  depends_on        = [module.primary_vpc, 
                       module.primary_public_gw, 
                       module.primary_vpc_address_prefix]
}

// This module is used to create subnet, which is used to create secondary_smc. The subnet CIDR range is passed manually based on the user input from variable file
module "secondary_subnet" {
  count     = length(var.smc_zone) > 1 ? 1 : 0
  providers = {
    ibm = ibm.secondary
  }
  source            = "./resources/ibmcloud/network/subnet"
  vpc_id            = local.secondary_vpc_id
  resource_group_id = data.ibm_resource_group.resource_group.id
  zones             = local.secondary_smc_zone
  subnet_name       = format("%s-secondary-subnet", var.cluster_prefix)
  subnet_cidr_block = var.secondary_cidr_block
  public_gateway    = local.secondary_public_gw_id
  tags              = local.tags
  depends_on        = [module.secondary_vpc, 
                       module.secondary_public_gw, 
                       module.secondary_vpc_address_prefix]
}

// This module is used to create subnet, which is used to create secondary_candidate_smc. The subnet CIDR range is passed manually based on the user input from variable file
module "secondary_candidate_subnet" {
  count     = length(var.smc_zone) > 2 ? 1 : 0
  providers = {
    ibm = ibm.secondary_candidate
  }
  source            = "./resources/ibmcloud/network/subnet"
  vpc_id            = local.secondary_candidate_vpc_id
  resource_group_id = data.ibm_resource_group.resource_group.id
  zones             = local.secondary_candidate_smc_zone
  subnet_name       = format("%s-secondary-candidate-subnet", var.cluster_prefix)
  subnet_cidr_block = var.secondary_candidate_cidr_block
  public_gateway    = local.secondary_candidate_public_gw_id
  tags              = local.tags
  depends_on        = [module.secondary_candidate_vpc, 
                       module.secondary_candidate_public_gw, 
                       module.secondary_candidate_vpc_address_prefix]
}

// This module is used to create the floating ip for bastion/login node
module "bastion_attach_fip" {
  providers = {
    ibm = ibm.primary
  }
  source            = "./resources/ibmcloud/network/floating_ip"
  floating_ip_name  = format("%s-bastion-fip", var.cluster_prefix)
  vsi_nw_id         = module.bastion_vsi.vsi_nw_id
  resource_group_id = data.ibm_resource_group.resource_group.id
  tags              = local.tags
}

// This module is used to create dns_zone
module "dns_zone" {
  providers = {
    ibm = ibm.primary
  }
  source            = "./resources/ibmcloud/network/dns_zone"
  name              = format("%s-dns", var.cluster_prefix)
  cluster_prefix    = var.cluster_prefix
  resource_group_id = data.ibm_resource_group.resource_group.id
  tags              = local.tags
  dns_domain        = var.dns_domain
  subnet_crn        = module.primary_subnet.subnet_crn
  depends_on        = [module.primary_subnet]
}

// This module creates primary_dns_custom_resolver to communicate with domain name
module "primary_dns_custom_resolver" {
  providers = {
    ibm = ibm.primary
  }
  source            = "./resources/ibmcloud/network/dns_custom_resolver"
  name              = format("%s-primary-vpc-resolver", var.cluster_prefix)
  instance_id       = module.dns_zone.resolver.service_guid
  tags              = local.tags
  dns_domain        = var.dns_domain
  subnet_crn        = module.primary_subnet.subnet_crn
  depends_on        = [module.primary_subnet]
 }

 // This module creates secondary_dns_custom_resolver to communicate with domain name
module "secondary_dns_custom_resolver" {
  count     = local.secondary_smc_region_name != null ? 1 : 0
  providers = {
    ibm = ibm.secondary
  }
  source            = "./resources/ibmcloud/network/dns_custom_resolver"
  name              = format("%s-secondary-vpc-resolver", var.cluster_prefix)
  instance_id       = module.dns_zone.resolver.service_guid
  tags              = local.tags
  dns_domain        = var.dns_domain
  subnet_crn        = module.secondary_subnet.*.subnet_crn[0]
  depends_on        = [module.secondary_subnet]
 }

 // This module creates secondary_candidate_dns_custom_resolver to communicate with domain name
module "secondary_candidate_dns_custom_resolver" {
  count     = local.secondary_candidate_smc_region_name != null ? 1 : 0
  providers = {
    ibm = ibm.secondary_candidate
  }
  source            = "./resources/ibmcloud/network/dns_custom_resolver"
  name              = format("%s-secondary-candidate-vpc-resolver", var.cluster_prefix)
  instance_id       = module.dns_zone.resolver.service_guid
  tags              = local.tags
  dns_domain        = var.dns_domain
  subnet_crn        = module.secondary_candidate_subnet.*.subnet_crn[0]
  depends_on        = [module.secondary_candidate_subnet]
 }

// This module creates primary_dns_permitted_network to access dns
module "primary_dns_permitted_network" {
  count      = local.primary_smc_region_name != null ? 1 : 0
  source     = "./resources/ibmcloud/network/dns_permitted_network"
  resolver   = module.dns_zone.resolver
  vpc_crn    = local.primary_vpc_crn
  depends_on = [module.dns_zone, 
                module.primary_vpc]
}

// This module creates secondary_dns_permitted_network to access dns
module "secondary_dns_permitted_network" {
  count      = local.secondary_smc_region_name != null ? 1 : 0
  source     = "./resources/ibmcloud/network/dns_permitted_network"
  resolver   = module.dns_zone.resolver
  vpc_crn    = local.secondary_vpc_crn
  depends_on = [module.dns_zone,
                module.secondary_vpc]
}

// This module creates secondary_candidate_dns_permitted_network to access dns
module "secondary_candidate_dns_permitted_network" {
  count      = local.secondary_candidate_smc_region_name != null ? 1 : 0
  source     = "./resources/ibmcloud/network/dns_permitted_network"
  resolver   = module.dns_zone.resolver
  vpc_crn    = local.secondary_candidate_vpc_crn
  depends_on = [module.dns_zone,
                module.secondary_candidate_vpc]
}

// The module is used to create a security group for only bastion/login nodes
module "login_security_group" {
  providers = {
    ibm = ibm.primary
  }
  source            = "./resources/ibmcloud/security/security_group"
  turn_on           = true
  sec_group_name    = format("%s-login-sg", var.cluster_prefix)
  vpc_id            = local.primary_vpc_id
  resource_group_id = data.ibm_resource_group.resource_group.id
  tags              = local.tags
  depends_on        = [module.transit_gw]
}

// This module create security_group inbound rule for login/bastion
module "login_sg_inbound_rule" {
  providers = {
    ibm = ibm.primary
  }
  source             = "./resources/ibmcloud/security/security_ssh_rule"
  security_group_ids = module.login_security_group.*.sec_group_id
  sg_direction       = "inbound"
  remote_ip_addr     = var.remote_allowed_ips
  depends_on         = [module.login_security_group]
}

// This module create security_group outbound rule for login/bastion
module "login_sg_outbound_rule" {
  providers = {
    ibm = ibm.primary
  }
  source             = "./resources/ibmcloud/security/security_rule"
  security_group_ids = module.login_security_group.*.sec_group_id
  sg_direction       = "outbound"
  remote_ip_addr     = ["0.0.0.0/0"]
  depends_on         = [module.login_security_group]
}

// The module is used to create a security group for primary_smc.
module "primary_security_group" {
  providers = {
    ibm = ibm.primary
  }
  source            = "./resources/ibmcloud/security/security_group"
  turn_on           = true
  sec_group_name    = format("%s-primary-sg", var.cluster_prefix)
  vpc_id            = local.primary_vpc_id
  resource_group_id = data.ibm_resource_group.resource_group.id
  tags              = local.tags
  depends_on        = [module.transit_gw]
}

// The module is used to create a security group for secondary_smc.
module "secondary_security_group" {
  count     = local.secondary_smc_region_name != null ? 1 : 0
  providers = {
    ibm = ibm.secondary
  }
  source            = "./resources/ibmcloud/security/security_group"
  turn_on           = true
  sec_group_name    = format("%s-secondary-sg", var.cluster_prefix)
  vpc_id            = local.secondary_vpc_id
  resource_group_id = data.ibm_resource_group.resource_group.id
  tags              = local.tags
  depends_on        = [module.transit_gw]
}

// The module is used to create a security group for secondary_candidate_smc.
module "secondary_candidate_security_group" {
  count     = local.secondary_candidate_smc_region_name != null ? 1 : 0
  providers = {
    ibm = ibm.secondary_candidate
  }
  source            = "./resources/ibmcloud/security/security_group"
  turn_on           = true
  sec_group_name    = format("%s-secondary-candidate-sg", var.cluster_prefix)
  vpc_id            = local.secondary_candidate_vpc_id
  resource_group_id = data.ibm_resource_group.resource_group.id
  tags              = local.tags
  depends_on        = [module.transit_gw]
}

// This module create primary_security_group inbound rule for primary_smc
module "primary_sg_inbound_rule" {
  providers = {
    ibm = ibm.primary
  }
  source             = "./resources/ibmcloud/security/security_rule"
  security_group_ids = module.primary_security_group.*.sec_group_id
  sg_direction       = "inbound"
  remote_ip_addr     = distinct(concat(local.lone_vpc_cidr, local.cidr_block_sg_allow))
  depends_on         = [module.primary_security_group]
}

// This module create primary_security_group inbound rule for secondary_smc
module "secondary_sg_inbound_rule" {
  count     = local.secondary_smc_region_name != null ? 1 : 0
  providers = {
    ibm = ibm.secondary
  }
  source             = "./resources/ibmcloud/security/security_rule"
  security_group_ids = module.secondary_security_group.*.sec_group_id
  sg_direction       = "inbound"
  remote_ip_addr     = distinct(concat(local.lone_vpc_cidr, local.cidr_block_sg_allow))
  depends_on         = [module.secondary_security_group]
}

// This module create primary_security_group inbound rule for secondary_candidate_smc
module "secondary_candidate_sg_inbound_rule" {
  count     = local.secondary_candidate_smc_region_name != null ? 1 : 0
  providers = {
    ibm = ibm.secondary_candidate
  }
  source             = "./resources/ibmcloud/security/security_rule"
  security_group_ids = module.secondary_candidate_security_group.*.sec_group_id
  sg_direction       = "inbound"
  remote_ip_addr     = distinct(concat(local.lone_vpc_cidr, local.cidr_block_sg_allow))
  depends_on         = [module.secondary_candidate_security_group]
}

// This module create primary_security_group outbound rule for primary_smc
module "primary_sg_outbound_rule" {
  providers = {
    ibm = ibm.primary
  }
  source             = "./resources/ibmcloud/security/security_rule"
  security_group_ids = module.primary_security_group.*.sec_group_id
  sg_direction       = "outbound"
  remote_ip_addr     = ["0.0.0.0/0"]
  depends_on         = [module.primary_security_group]
}

// This module create primary_security_group outbound rule for secondary_smc
module "secondary_sg_outbound_rule" {
  count     = local.secondary_smc_region_name != null ? 1 : 0
  providers = {
    ibm = ibm.secondary
  }
  source             = "./resources/ibmcloud/security/security_rule"
  security_group_ids = module.secondary_security_group.*.sec_group_id
  sg_direction       = "outbound"
  remote_ip_addr     = ["0.0.0.0/0"]
  depends_on         = [module.secondary_security_group]
}

// This module create primary_security_group outbound rule for secondary_candidate_smc
module "secondary_candidate_sg_outbound_rule" {
  count     = local.secondary_candidate_smc_region_name != null ? 1 : 0
  providers = {
    ibm = ibm.secondary_candidate
  }
  source             = "./resources/ibmcloud/security/security_rule"
  security_group_ids = module.secondary_candidate_security_group.*.sec_group_id
  sg_direction       = "outbound"
  remote_ip_addr     = ["0.0.0.0/0"]
  depends_on         = [module.secondary_candidate_security_group]
}

// This module is used to create the login/bastion node to access all other nodes in the SMC cluster
module "bastion_vsi" {
  providers = {
    ibm = ibm.primary
  }
  source              = "./resources/ibmcloud/compute/bastion_vsi"
  vsi_name_prefix     = format("%s-bastion", var.cluster_prefix)
  vpc_id              = local.primary_vpc_id
  vpc_zone            = local.primary_smc_zone
  resource_grp_id     = data.ibm_resource_group.resource_group.id
  vsi_subnet_id       = module.login_subnet.subnet_id
  vsi_security_group  = [module.login_security_group.*.sec_group_id]
  vsi_profile         = var.bastion_host_instance_type
  vsi_image_id        = module.bastion_image.image_id
  vsi_user_public_key = local.primary_ssh_key_id
  vsi_meta_public_key = local.public_key_content
  user_data           = data.template_file.metadata_startup_script.rendered
  tags                = local.tags
  depends_on          = [module.transit_gw]
}

// This module is used to create the primary_smc vsi
module "primary_smc" {
  providers = {
    ibm = ibm.primary
  }
  source             = "./resources/ibmcloud/compute/smc_vsi"
  vsi_name_prefix    = format("%s-primary", var.cluster_prefix)
  vpc_id             = local.primary_vpc_id
  vpc_zone           = local.primary_smc_zone
  resource_grp_id    = data.ibm_resource_group.resource_group.id
  vsi_subnet_id      = module.primary_subnet.subnet_id
  ipv4_ip            = local.primary_smc_host_ip
  vsi_security_group = local.primary_security_group_id
  vsi_profile        = data.ibm_is_instance_profile.smc_profile.name
  vsi_image_id       = (local.smc_image_mapping_entry_found ? local.new_primary_smc_image_id : 
                        module.primary_smc_image_check.*.image_id[0])
  keys               = local.primary_ssh_key_id
  volume_capacity    = local.volume_capacity
  volume_profile     = local.volume_profile
  tags               = local.tags
  resolver           = module.dns_zone.resolver
  user_data          = "${data.template_file.primary_user_data.rendered} ${file("${path.module}/scripts/user_data_symphony_smc.sh")}"
  dns_domain         = var.dns_domain
  depends_on         = [module.transit_gw, module.primary_dns_permitted_network]
}

// This module is used to create the secondary_smc vsi
module "secondary_smc" {
  count     = length(var.smc_zone) > 1 ? 1 : 0
  providers = {
    ibm = ibm.secondary
  }
  source             = "./resources/ibmcloud/compute/smc_vsi"
  vsi_name_prefix    = format("%s-secondary", var.cluster_prefix)
  vpc_id             = local.secondary_vpc_id
  vpc_zone           = local.secondary_smc_zone
  resource_grp_id    = data.ibm_resource_group.resource_group.id
  vsi_subnet_id      = module.secondary_subnet.*.subnet_id[0]
  ipv4_ip            = local.secondary_smc_host_ip
  vsi_security_group = local.secondary_security_group_id
  vsi_profile        = data.ibm_is_instance_profile.smc_profile.name
  vsi_image_id       = (local.smc_image_mapping_entry_found ? local.new_secondary_smc_image_id : 
                        module.secondary_smc_image_check.*.image_id[0])
  keys               = local.secondary_ssh_key_id
  volume_capacity    = local.volume_capacity
  volume_profile     = local.volume_profile
  tags               = local.tags
  resolver           = module.dns_zone.resolver
  user_data          = "${data.template_file.secondary_user_data[count.index].rendered} ${file("${path.module}/scripts/user_data_symphony_smc.sh")}"
  dns_domain         = var.dns_domain
  depends_on         = [module.transit_gw, module.secondary_dns_permitted_network]
}

// This module is used to create the secondary_candidate_smc vsi
module "secondary_candidate_smc" {
  count     = length(var.smc_zone) > 2 ? 1 : 0
  providers = {
    ibm = ibm.secondary_candidate
  }
  source             = "./resources/ibmcloud/compute/smc_vsi"
  vsi_name_prefix    = format("%s-secondary-candidate", var.cluster_prefix)
  vpc_id             = local.secondary_candidate_vpc_id
  vpc_zone           = local.secondary_candidate_smc_zone
  resource_grp_id    = data.ibm_resource_group.resource_group.id
  vsi_subnet_id      = module.secondary_candidate_subnet.*.subnet_id[0]
  ipv4_ip            = local.secondary_candidate_smc_host_ip
  vsi_security_group = local.secondary_candidate_security_group_id
  vsi_profile        = data.ibm_is_instance_profile.smc_profile.name
  vsi_image_id       = (local.smc_image_mapping_entry_found ? local.new_secondary_candidate_smc_image_id : 
                        module.secondary_candidate_smc_image_check.*.image_id[0])
  keys               = local.secondary_candidate_ssh_key_id
  volume_capacity    = local.volume_capacity
  volume_profile     = local.volume_profile
  tags               = local.tags
  resolver           = module.dns_zone.resolver
  user_data          = "${data.template_file.secondary_candidate_user_data[count.index].rendered} ${file("${path.module}/scripts/user_data_symphony_smc.sh")}"
  dns_domain         = var.dns_domain
  depends_on         = [module.transit_gw, module.secondary_candidate_dns_permitted_network]
}