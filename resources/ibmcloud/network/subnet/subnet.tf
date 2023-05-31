###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
   Creates IBM Cloud new Subnet(s).
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "vpc_id" {}
variable "zones" {}
variable "subnet_name" {}
variable "subnet_cidr_block" {}
variable "public_gateway" {}
variable "resource_group_id" {}
variable "tags" {}

resource "ibm_is_subnet" "subnet" {
  name            = "${var.subnet_name}"
  vpc             = var.vpc_id[0]
  resource_group  = var.resource_group_id
  zone            = var.zones
  ipv4_cidr_block = var.subnet_cidr_block
  public_gateway  = var.public_gateway[0]
  tags            = var.tags
}

output "subnet_id" {
  value = ibm_is_subnet.subnet.id
}

output "subnet_crn" {
  value = ibm_is_subnet.subnet.crn
}

output "ipv4_cidr_block" {
  value = ibm_is_subnet.subnet.ipv4_cidr_block
}