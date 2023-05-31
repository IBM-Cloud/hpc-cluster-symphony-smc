###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

# Or we can switch the region via export IC_REGION="eu-gb"
terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.53.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.0.1"
    }
  }
}

# Providers for SMC
provider "ibm" {
  ibmcloud_api_key = var.api_key
  region           = local.primary_smc_region
  alias            = "primary"
}
provider "ibm" {
  ibmcloud_api_key = var.api_key
  region           = local.secondary_smc_region != null ? local.secondary_smc_region : ""
  alias            = "secondary"
}
provider "ibm" {
  ibmcloud_api_key = var.api_key
  region           = local.secondary_candidate_smc_region != null ? local.secondary_candidate_smc_region : ""
  alias            = "secondary_candidate"
}

// Providers for existing_lone_vpc
provider "ibm" {
  ibmcloud_api_key = var.api_key
  region           = local.lone_1_region
  alias            = "lone_1"
}
provider "ibm" {
  ibmcloud_api_key = var.api_key
  region           = local.lone_2_region
  alias            = "lone_2"
}
provider "ibm" {
  ibmcloud_api_key = var.api_key
  region           = local.lone_3_region
  alias            = "lone_3"
}