###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    Creates a Bastion/Jump Host Instance for smc cluster host access .
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
variable "vsi_user_public_key" {}
variable "vsi_meta_public_key" {}
variable "resource_grp_id" {}
variable "tags" {}
variable "user_data" {}

resource "ibm_is_instance" "login_instance" {
  name    = var.vsi_name_prefix
  image   = var.vsi_image_id
  profile = var.vsi_profile
  tags    = var.tags
  primary_network_interface {
    subnet          = var.vsi_subnet_id
    security_groups = var.vsi_security_group[0]
  }
  vpc            = var.vpc_id[0]
  zone           = var.vpc_zone
  resource_group = var.resource_grp_id
  keys           = var.vsi_user_public_key
  user_data      = var.user_data
  boot_volume {
    name = format("%s-boot-vol", var.vsi_name_prefix)
  }
}

output "vsi_id" {
  value = ibm_is_instance.login_instance.*.id
}

output "vsi_private_ip" {
  value = ibm_is_instance.login_instance.primary_network_interface[0].primary_ip.0.address
}

output "vsi_nw_id" {
  value = ibm_is_instance.login_instance.primary_network_interface[0].id
}