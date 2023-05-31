###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
   Creates new IBM Virtual Private Cloud.
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "vpc_name" {}
variable "vpc_address_prefix_management" {}
variable "resource_group_id" {}
variable "tags" {}

resource "ibm_is_vpc" "vpc" {
  name                      = var.vpc_name
  address_prefix_management = var.vpc_address_prefix_management
  resource_group            = var.resource_group_id
  tags                      = var.tags
}

output "vpc_id" {
  value = ibm_is_vpc.vpc.id
}

output "vpc_crn" {  
  value = ibm_is_vpc.vpc.crn
}