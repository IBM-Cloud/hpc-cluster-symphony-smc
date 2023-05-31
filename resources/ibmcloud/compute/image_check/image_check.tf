###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

/*
    Checks image detail and gets image id
*/

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

variable "image_name" {}

data "ibm_is_image" "image" {
  // Validate image_name exist or not
  name = var.image_name
}

output "image_id" {
  value = data.ibm_is_image.image.id
}