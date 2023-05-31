
###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    Creates IBM Cloud login subnet.
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
variable "login_subnet_name" {}
variable "subnet_cidr_block" {}
variable "resource_group_id" {}
variable "tags" {}

resource "ibm_is_subnet" "login_subnet" {
  name            = "${var.login_subnet_name}"
  vpc             = var.vpc_id[0]
  resource_group  = var.resource_group_id
  zone            = var.zones
  ipv4_cidr_block = var.subnet_cidr_block
  tags            = var.tags
}

output "subnet_id" {
  value = ibm_is_subnet.login_subnet.id
}