###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
   Add Permitted_network to IBM Cloud DNS Zone.
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "resolver" {}
variable "vpc_crn" {}

resource "time_sleep" "wait_30_seconds" {
  create_duration = "30s"
}

resource "ibm_dns_permitted_network" "dns_permitted_network" {
  instance_id = var.resolver.service_guid
  zone_id     = var.resolver.zone_id
  vpc_crn     = var.vpc_crn[0]
  type        = "vpc"
  depends_on  = [time_sleep.wait_30_seconds]
}