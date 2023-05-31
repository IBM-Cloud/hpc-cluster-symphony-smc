###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    Creates IBM Cloud floating ip.
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "floating_ip_name" {}
variable "vsi_nw_id" {}
variable "resource_group_id" {}
variable "tags" {}

resource "ibm_is_floating_ip" "floating_ip" {
  name           = var.floating_ip_name
  target         = var.vsi_nw_id
  resource_group = var.resource_group_id
  tags           = var.tags
}

output "floating_ip_id" {
  value = ibm_is_floating_ip.floating_ip.id
}

output "floating_ip_addr" {
  value = ibm_is_floating_ip.floating_ip.address
}