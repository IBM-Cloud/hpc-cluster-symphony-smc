###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

# This file contains the complete information on all the validations performed from the code during the generate plan process
# Validations are performed to make sure, the appropriate error messages are displayed to user in-order to provide required input parameter

locals {
  // Validation for the length of lone_vpc_name must be less than or equal to 3
  validate_lone_vpc_name_length     = var.lone_vpc_name != null ? length(var.lone_vpc_name) > 3 ? false : true : true
  validate_lone_vpc_name_length_msg = "The lone_vpc_name must be less than or equal to 3."
  validate_lone_vpc_name_length_chk = regex("^${local.validate_lone_vpc_name_length_msg}$", (local.validate_lone_vpc_name_length ? local.validate_lone_vpc_name_length_msg : "" ))

  // Validation for the length of lone_vpc_region must be less than or equal to 3
  validate_lone_vpc_region_length     = var.lone_vpc_region != null ? length(var.lone_vpc_region) > 3 ? false : true : true
  validate_lone_vpc_region_length_msg = "The lone_vpc_region must be less than or equal to 3."
  validate_lone_vpc_region_length_chk = regex("^${local.validate_lone_vpc_region_length_msg}$", (local.validate_lone_vpc_region_length ? local.validate_lone_vpc_region_length_msg : "" ))

  // Validation for the lone_vpc_name existing along with lone_vpc_region exist or not 
  validate_lone_vpc_name_check = var.lone_vpc_name == null && var.lone_vpc_region != null ? false : true
  validate_lone_vpc_name_msg   = "Pass lone_vpc_name along with lone_vpc_region."
  validate_lone_vpc_name_chk   = regex("^${local.validate_lone_vpc_name_msg}$", ( local.validate_lone_vpc_name_check ? local.validate_lone_vpc_name_msg : "" ))

  // Validation for the lone_vpc_region existing along with lone_vpc_name exist or not 
  validate_lone_vpc_region_check = var.lone_vpc_name != null && var.lone_vpc_region == null ? false : true
  validate_lone_vpc_region_msg   = "Pass lone_vpc_region along with lone_vpc_name."
  validate_lone_vpc_region_chk   = regex("^${local.validate_lone_vpc_region_msg}$", (local.validate_lone_vpc_region_check ? local.validate_lone_vpc_region_msg : "" ))

  // Validation for comparing of lone_vpc_name and lone_vpc_region
  validate_lone_length_check = (var.lone_vpc_name != null && 
                                var.lone_vpc_region != null && 
                                local.validate_lone_vpc_name_length && 
                                local.validate_lone_vpc_region_length ? length(var.lone_vpc_name) == length(var.lone_vpc_region) : 
                                true)
  validate_lone_length_msg   = "The length of lone_vpc_name has to be equal to the length of lone_vpc_region vice versa."
  validate_lone_length_chk   = regex("^${local.validate_lone_length_msg}$", (local.validate_lone_length_check ? local.validate_lone_length_msg : "" ))

  // Validation for the lone_vpc_region should not have ["us-south-3"]
  validate_lone_vpc_region = (var.lone_vpc_region != null && 
                              local.validate_lone_vpc_region_check ? alltrue([for a in var.lone_vpc_region : 
                              can(regex("^[a-z]*\\-[a-z]*$", a))]) : "true")
  validate_lone_region_msg = "Provided lone_vpc_region format is not valid. Check if region format has comma instead of dot and there should be double quotes between each region range if using multiple zones ranges."
  validate_lone_region_chk = regex("^${local.validate_lone_region_msg}$", (local.validate_lone_vpc_region == "true" ? local.validate_lone_region_msg : ""))

  // Validation for the lone_vpc_name should not contain null value in a list
  validate_lone_vpc_name_null = (var.lone_vpc_name != null && 
                              local.validate_lone_vpc_region_check ? alltrue([for vpc_name in var.lone_vpc_name : vpc_name != ""]) : "true")
  validate_lone_vpc_name_null_msg = "Provided lone_vpc_name format is not valid. Check if passed null value in list"
  validate_lone_vpc_name_null_chk = regex("^${local.validate_lone_vpc_name_null_msg}$", (local.validate_lone_vpc_name_null == "true" ? local.validate_lone_vpc_name_null_msg : ""))

  // Validate lone_vpc creation
  lone_vpc_validation = (local.validate_lone_vpc_name_length && 
                         local.validate_lone_vpc_region_length && 
                         local.validate_lone_vpc_name_check && 
                         local.validate_lone_vpc_region_check && 
                         local.validate_lone_vpc_name_null &&
                         local.validate_lone_length_check && 
                         local.validate_lone_vpc_region == "true" ? true : false)
}
