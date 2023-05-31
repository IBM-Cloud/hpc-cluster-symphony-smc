###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    Checks existing_vpc detail and gets vpc id and crn
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "existing_vpc_name" {}

data "ibm_is_vpc" "existing_lone_vpc" {
  // Validate existing_lone_vpc exist or not
  name = var.existing_vpc_name
}

// Fetching existing vpc cidr to access security group
data "ibm_is_vpc_address_prefixes" "existing_address_prefix" {
  vpc = data.ibm_is_vpc.existing_lone_vpc.id
}

output "existing_vpc_id" {
  value = data.ibm_is_vpc.existing_lone_vpc.id
}

output "existing_vpc_crn" {
  value = data.ibm_is_vpc.existing_lone_vpc.crn
}

output "existing_vpc_cidr" {
  value = data.ibm_is_vpc_address_prefixes.existing_address_prefix.address_prefixes[0].cidr
}