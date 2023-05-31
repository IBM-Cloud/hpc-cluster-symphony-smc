###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    Creates IBM Cloud DNS records.
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "name" {}
variable "rdata" {}
variable "dns_domain" {}
variable "resolver" {}

locals{
  ttl = 300
}

resource "ibm_dns_resource_record" "a_record" {
  instance_id = var.resolver.service_guid
  zone_id     = var.resolver.zone_id
  type        = "A"
  name        = var.name
  rdata       = var.rdata
  ttl         = local.ttl
}

resource "ibm_dns_resource_record" "ptr_record" {
  instance_id = var.resolver.service_guid
  zone_id     = var.resolver.zone_id
  type        = "PTR"
  name        = var.rdata
  rdata       = format("%s.%s", var.name, var.dns_domain)
  ttl         = local.ttl
  depends_on  = [ibm_dns_resource_record.a_record]
}