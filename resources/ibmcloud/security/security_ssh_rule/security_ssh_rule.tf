###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    Creates security groups ssh rule.
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "security_group_ids" {}
variable "sg_direction" {}
variable "remote_ip_addr" {}

resource "ibm_is_security_group_rule" "security_ssh_rule" {
  count     = length(var.remote_ip_addr)
  group     = var.security_group_ids[0]
  direction = var.sg_direction
  remote    = var.remote_ip_addr[count.index]
  tcp {
    port_min = 22
    port_max = 22
  }
}

output "security_rule_id" {
  value = ibm_is_security_group_rule.security_ssh_rule.*.id
}