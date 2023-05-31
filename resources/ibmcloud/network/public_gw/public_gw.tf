###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    Creates IBM Cloud Public/internet gateway.
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "public_gw_name" {}
variable "vpc_id" {}
variable "zones" {}
variable "resource_group_id" {}
variable "tags" {}

resource "ibm_is_public_gateway" "public_gateway" {
  count          = var.zones != null ? 1 : 0
  name           = "${var.public_gw_name}"
  vpc            = var.vpc_id[0]
  resource_group = var.resource_group_id
  zone           = var.zones
  tags           = var.tags
}

output "public_gw_id" {
  value = ibm_is_public_gateway.public_gateway.*.id
}