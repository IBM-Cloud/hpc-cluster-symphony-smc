###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    Creates new IBM VPC address prefixes.
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "vpc_id" {}
variable "address_name" {}
variable "zone" {}
variable "cidr_block" {}

resource "ibm_is_vpc_address_prefix" "vpc_address_prefix" {
  name  = var.address_name
  zone  = var.zone
  vpc   = var.vpc_id[0]
  cidr  = var.cidr_block
}

output "vpc_addr_prefix_id" {
  value = ibm_is_vpc_address_prefix.vpc_address_prefix.*.id
}