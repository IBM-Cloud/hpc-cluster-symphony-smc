###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    Checks ssh key detail and gets sshkey id
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "ssh_key_name" {}

locals {
ssh_key_list          = split(",", var.ssh_key_name)
ssh_key_id_list       = [
    for name in local.ssh_key_list:
    data.ibm_is_ssh_key.ssh_key[name].id
  ]
}

data "ibm_is_ssh_key" "ssh_key" {
  for_each = toset(split(",", var.ssh_key_name))
  name     = each.value
}

output "ssh_key_id_list" {
  value = local.ssh_key_id_list
}