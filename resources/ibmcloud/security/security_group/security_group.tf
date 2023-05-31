###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    Creates new IBM Cloud security group.
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "turn_on" {}
variable "sec_group_name" {}
variable "vpc_id" {}
variable "resource_group_id" {}
variable "tags" {}

resource "ibm_is_security_group" "security_group" {
  name           = var.sec_group_name
  vpc            = length(var.vpc_id) > 0 ? var.vpc_id[0] : null
  resource_group = var.resource_group_id
  tags           = var.tags
}

output "sec_group_id" {
  value = try(ibm_is_security_group.security_group.id, null)
}