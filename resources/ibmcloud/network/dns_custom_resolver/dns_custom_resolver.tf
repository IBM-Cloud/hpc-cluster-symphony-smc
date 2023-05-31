###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
   Add custom resolver to IBM Cloud DNS resource instance.
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "name" {}
variable "subnet_crn" {}
variable "instance_id" {}
variable "tags" {}
variable "dns_domain" {}

resource "ibm_dns_custom_resolver" "custom_resolver" {
  name              = var.name
  instance_id       = var.instance_id
  description       = "Private DNS custom resolver for VPC DNS communication."
  high_availability = false
  enabled           = true
  locations {
    subnet_crn = var.subnet_crn
    enabled    = true
  }
}

output "dns_server_ip" {
  value = ibm_dns_custom_resolver.custom_resolver.locations[0].dns_server_ip
}