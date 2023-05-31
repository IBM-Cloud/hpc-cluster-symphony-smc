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

variable "cluster_prefix" {}
variable "resource_group_id" {}
variable "tags" {}
variable "dns_domain" {}
variable "subnet_crn" {}
variable "name" {}

resource "ibm_resource_instance" "dns_service" {
  name              = var.name
  resource_group_id = var.resource_group_id
  location          = "global"
  service           = "dns-svcs"
  plan              = "standard-dns"
  tags              = var.tags
}

resource "ibm_dns_zone" "dns_zone" {
  name        = var.dns_domain
  instance_id = ibm_resource_instance.dns_service.guid
  description = "Private DNS Zone for VPC DNS communication."
  label       = var.cluster_prefix
}

output "resolver" {
  value = {
    service_guid = ibm_resource_instance.dns_service.guid
    zone_id      = ibm_dns_zone.dns_zone.zone_id
    dns_domain   = var.dns_domain
  }
}