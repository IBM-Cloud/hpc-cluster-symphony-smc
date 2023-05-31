###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    Creates smc host's.
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "vsi_name_prefix" {}
variable "vpc_id" {}
variable "vsi_subnet_id" {}
variable "vpc_zone" {}
variable "vsi_security_group" {}
variable "vsi_profile" {}
variable "vsi_image_id" {}
variable "keys" {}
variable "resource_grp_id" {}
variable "tags" {}
variable "volume_capacity" {}
variable "volume_profile" {}
variable "ipv4_ip" {}
variable "dns_domain" {}
variable "resolver" {}
variable "user_data" {}

data "ibm_is_volume_profile" "smc_data" {
  name = var.volume_profile
}

resource "ibm_is_volume" "smc_data" {
  name           = "${var.vsi_name_prefix}-data"
  profile        = data.ibm_is_volume_profile.smc_data.name
  capacity       = var.volume_capacity
  zone           = var.vpc_zone
  resource_group = var.resource_grp_id
  tags           = var.tags
}

module "resolver_resource_record" {
  source      = "../../network/dns_resource_record"
  resolver    = var.resolver
  name        = var.vsi_name_prefix
  rdata       = var.ipv4_ip[0]
  dns_domain  = var.dns_domain
}

resource "ibm_is_instance" "smc_instance" {
  count          = 1
  name           = var.vsi_name_prefix
  image          = var.vsi_image_id
  profile        = var.vsi_profile
  vpc            = var.vpc_id[0]
  zone           = var.vpc_zone
  keys           = var.keys
  resource_group = var.resource_grp_id
  user_data      = var.user_data
  tags           = var.tags
  primary_network_interface {
    name         = "eth0"
    subnet       = var.vsi_subnet_id
    security_groups = var.vsi_security_group[0]
    primary_ip {
      address = var.ipv4_ip[count.index]
    }
  }
  depends_on  = [module.resolver_resource_record]
}

resource "ibm_is_instance_volume_attachment" "data_volume" {
  instance                           = ibm_is_instance.smc_instance[0].id
  name                               = "${var.vsi_name_prefix}-symphony-data"
  volume                             = ibm_is_volume.smc_data.id
  delete_volume_on_attachment_delete = false
  delete_volume_on_instance_delete   = true
  depends_on                         = [ibm_is_volume.smc_data,ibm_is_instance.smc_instance]
}

output "vsi_id" {
  value = ibm_is_instance.smc_instance[0].id
}

output "vsi_private_ip" {
  value = ibm_is_instance.smc_instance[0].primary_network_interface[0].primary_ip.0.address
}