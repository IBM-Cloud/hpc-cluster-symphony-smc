###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
   Creates new IBM Cloud Transit Gateway.
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "transit_gw_name" {}
variable "transit_gw_location" {}
variable "resource_group_id" {}
variable "tags" {}
variable "smc_vpc_crn" {} 
variable "lone_vpc_crn" {} 
variable "smc_region" {}

resource "ibm_tg_gateway" "transit_gw"{
name           = var.transit_gw_name
location       = var.transit_gw_location
global         = true
resource_group = var.resource_group_id
tags           = var.tags
}  

resource "ibm_tg_connection" "lone_vpc_connection" {
  count        = length(var.lone_vpc_crn)
  gateway      = ibm_tg_gateway.transit_gw.id
  network_type = "vpc"
  name         = "lone-${count.index+1}"
  network_id   = var.lone_vpc_crn[count.index]
  depends_on   = [ibm_tg_gateway.transit_gw]
}

resource "ibm_tg_connection" "smc_vpc_connection" {
  count        = length(var.smc_region)
  gateway      = ibm_tg_gateway.transit_gw.id
  network_type = "vpc"
  name         = "smc-${count.index+1}"
  network_id   = var.smc_vpc_crn[count.index]
  depends_on   = [ibm_tg_gateway.transit_gw]
}