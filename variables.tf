###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

### About VPC resources

variable "lone_vpc_name" {
  type        = list(string)
  default     = null
  description = "Name of an existing Lone Symphony VPC, lone_vpc_name and lone_vpc_region should be in same order. If no value is given, then need to add existing_lone_vpc manually with SMC transit_gateway. Note: lone_vpc_name support maximum of 3 existing_lone_vpc_name. [Learn more](https://cloud.ibm.com/docs/vpc)."
}

variable "lone_vpc_region" {
  type        = list(string)
  default     = null
  description = "Name of the IBM Cloud region where the existing Lone Symphony VPC, lone_vpc_name and lone_vpc_region should be in same order (Examples: us-east, us-south, etc.). Note: lone_vpc_region support maximum of 3 existing_lone_vpc_region. For more information, see [Region and data center locations for resource deployment](https://cloud.ibm.com/docs/overview?topic=overview-locations)."
}

variable "ssh_key_name" {
  type        = string
   description = "Comma-separated list of names of the SSH key configured in your IBM Cloud account that is used to establish a connection to the Symphony resources SMC vsi. NOTE: SSH key-name should be unique in all region with same name. Ensure the SSH key is present in the same resource group and region where the cluster is being provisioned. If you do not have an SSH key in your IBM Cloud account, create one by using the instructions given here. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-ssh-keys)."
}

variable "api_key" {
  type        = string
  sensitive   = true
  description = "This is the API key for IBM Cloud account in which the Symphony Multi cluster needs to be deployed. [Learn more](https://cloud.ibm.com/docs/account?topic=account-userapikey)."
  validation {
    condition     = var.api_key != ""
    error_message = "API key for IBM Cloud must be set."
  }
}

variable "sym_license_confirmation" {
  type        = string
  description = "Confirm your use of IBM Symphony Multi Cluster licenses. By entering 'true' for the property you have agreed to one of the two conditions. 1. You are using the software in production and confirm you have sufficient licenses to cover your use under the International Program License Agreement (IPLA). 2. You are evaluating the software and agree to abide by the International License Agreement for Evaluation of Programs (ILAE). NOTE: Failure to comply with licenses for production use of software is a violation of IBM International Program License Agreement. [Learn more](https://www.ibm.com/software/passportadvantage/programlicense.html)."
  validation {
    condition     = var.sym_license_confirmation == "true"
    error_message = "Confirm your use of IBM Symphony Multi Cluster licenses. By entering 'true' for the property you have agreed to one of the two conditions. 1. You are using the software in production and confirm you have sufficient licenses to cover your use under the International Program License Agreement (IPLA). 2. You are evaluating the software and agree to abide by the International License Agreement for Evaluation of Programs (ILAE). NOTE: Failure to comply with licenses for production use of software is a violation of IBM International Program License Agreement. [Learn more](https://www.ibm.com/software/passportadvantage/programlicense.html)."
  }
}

variable "smc_zone" {
  type        = list(string)
  description = "IBM Cloud zone name within the selected region where the Symphony Multi Cluster resources should be deployed. Note: smc_zone support maximum of 3 zone. Examples as [\"us-south-1\",\"eu-gb-3\",\"jp-tok-2\"] or [\"us-south-1\",\"us-south-1\",\"us-south-3\"] or [\"jp-tok-3\",\"au-syd-3\"] or [\"jp-tok-2\"]. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-creating-a-vpc-in-a-different-region#get-zones-using-the-cli)."
  validation {
    condition = alltrue([
      for zone in var.smc_zone : can(regex("[a-z\\s]+-+[a-z\\s]{1,20}-+[1-3]{1}", zone))
    ])
    error_message = "Provided smc_zone format is not valid. Check if zone format has comma instead of dot and there should be double quotes between each zone range if using multiple zones ranges. For multiple zones use format [\"us-south-1\",\"jp-tok-2\",\"ca-tor-3\"]."
  }
  validation {
    condition     = length(var.smc_zone) <= 3
    error_message = "The smc_zone must be less than or equal to 3."
  }
}

variable "resource_group" {
  type        = string
  default     = "Default"
  description = "Resource group name from your IBM Cloud account where the VPC resources should be deployed. [Learn more](https://cloud.ibm.com/docs/account?topic=account-rgs)."
}

variable "cluster_prefix" {
  type        = string
  default     = "hpcc-smc"
  description = "Prefix that is used to name the Symphony Multi cluster and IBM Cloud resources that are provisioned to build the Symphony Multi cluster instance. You cannot create more than one instance of the Symphony Multi cluster with the same name. Make sure that the name is unique. Enter a prefix name, such as my-hpcc."
}

variable "cluster_id" {
  type        = string
  default     = "HPCMultiCluster"
  description = "ID of the cluster used by Symphony Multi Cluster for configuration of resources. This must be up to 39 alphanumeric characters including the underscore (_), the hyphen (-), and the period (.). Other special characters and spaces are not allowed. Do not use the name of any host or user as the name of your cluster. You cannot change it after installation."
  validation {
    condition     = 0 < length(var.cluster_id) && length(var.cluster_id) < 40 && can(regex("^[a-zA-Z0-9_.-]+$", var.cluster_id))
    error_message = "The ID must be up to 39 alphanumeric characters including the underscore (_), the hyphen (-), and the period (.). Other special characters and spaces are not allowed."
  }
}

variable "dns_domain" {
  type        = string
  default     = "smc.ibmhpc.com"
  description = "IBM Cloud DNS Services domain name to be used for the Symphony Multi Cluster host."
}

variable "smc_image_name" {
  type        = string
  default     = "hpcc-symphony732-rhel86-smc-v1"
  description = "Name of the custom image that you want to use to create virtual server instances in your IBM Cloud account to deploy the IBM Symphony Multi Cluster. By default, the automation uses a base image with additional software packages mentioned [here](https://cloud.ibm.com/docs/hpc-spectrum-symphony#create-custom-image). If you would like to include your application-specific binary files, follow the instructions in [ Planning for custom images ](https://cloud.ibm.com/docs/vpc?topic=vpc-planning-custom-images) to create your own custom image and use that to build the IBM Symphony cluster through this offering."
}

variable "smc_host_instance_type" {
  type        = string
  default     = "bx2-4x16"
  description = "Specify the virtual server instance profile type name to be used to create the Symphony Multi Cluster host. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles)."
  validation {
    condition     = can(regex("^[^\\s]+-[0-9]+x[0-9]+", var.smc_host_instance_type))
    error_message = "The profile must be a valid profile name."
  }
}

variable "bastion_host_instance_type" {
  type        = string
  default     = "bx2-2x8"
  description = "Specify the virtual server instance profile type name to be used to create the bastion node for the Symphony Multi Cluster. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles)."
  validation {
    condition     = can(regex("^[^\\s]+-[0-9]+x[0-9]+", var.bastion_host_instance_type))
    error_message = "The profile must be a valid profile name."
  }
}

variable "remote_allowed_ips" {
  type        = list(string)
  description = "Comma-separated list of IP addresses that can access the Symphony Multi Cluster instance through an SSH interface. For security purposes, provide the public IP addresses assigned to the devices that are authorized to establish SSH connections (for example, [\"169.45.117.34\"]). To fetch the IP address of the device, use https://ipv4.icanhazip.com/."
  validation {
    condition = alltrue([
      for ip in var.remote_allowed_ips : !contains(["0.0.0.0/0", "0.0.0.0"], ip)
    ])
    error_message = "For the purpose of security provide the public IP address(es) assigned to the device(s) authorized to establish SSH connections. Use https://ipv4.icanhazip.com/ to fetch the ip address of the device."
  }
  validation {
    condition = alltrue([
      for a in var.remote_allowed_ips : can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", a))
    ])
    error_message = "Provided IP address format is not valid. Check if Ip address format has comma instead of dot and there should be double quotes between each IP address range if using multiple ip ranges. For multiple IP address use format [\"169.45.117.34\",\"128.122.144.145\"]."
  }
}

variable "lone_symphony_cidr_block" {
  type        = list(string)
  default     = null
  description = "Comma-separated list of CIDR blocks which used in Spectrum Symphony Cluster(Lone Symphony Cluster)."
  validation {
    condition = var.lone_symphony_cidr_block != null ? alltrue([
      for lone_cidr in var.lone_symphony_cidr_block : !contains(["0.0.0.0"], lone_cidr)
    ]) : true
    error_message = "For the purpose of security and to enable connection between SMC and Lone Symphony Cluster provide the correct CIDR block. Example [\"10.0.0.0/8\"]."
  }
  validation {
    condition = var.lone_symphony_cidr_block != null ? alltrue([
      for a in var.lone_symphony_cidr_block : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(\\/([8-9]|[12][0-9]|3[0-2]){1,2})$", a))
    ]) : true
    error_message = "Provided IP address format is not valid. Check if Ip address format has comma instead of dot and there should be double quotes between each IP address range if using multiple ip ranges. For multiple IP address use format [\"169.45.117.34\",\"128.122.144.145\"]."
  }
}

variable "login_cidr_block" {
  type        = list(string)
  default     = ["10.10.4.0/28"]
  description = "IBM Cloud VPC address prefixes that are needed for VPC creation. Provide a CIDR address prefix for VPC creation. For more information, see [Bring your own subnet](https://cloud.ibm.com/docs/vpc?topic=vpc-configuring-address-prefixes)."
  validation {
    condition = alltrue([
      for a in var.login_cidr_block : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(\\/([9]|[12][0-9]))$", a))
    ])
    error_message = "Our Automation supports only a single AZ to deploy resources. Provide a Login CIDR range of address prefix."
  }
}

variable "primary_cidr_block" {
  type        = string
  default     = "10.10.0.0/24"
  description = "IBM Cloud VPC address prefixes that are needed for VPC creation. Provide a CIDR address prefix for Primary VPC creation. For more information, see [Bring your own subnet](https://cloud.ibm.com/docs/vpc?topic=vpc-configuring-address-prefixes)."
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(\\/([9]|[12][0-9]))$", var.primary_cidr_block))
    error_message = "Our Automation supports only a single AZ to deploy resources. Provide a Primary CIDR range of address prefix."
  }
}

variable "secondary_cidr_block" {
  type        = string
  default     = "10.20.0.0/24"
  description = "IBM Cloud VPC address prefixes that are needed for VPC creation. Provide a CIDR address prefix for Secondary VPC creation. For more information, see [Bring your own subnet](https://cloud.ibm.com/docs/vpc?topic=vpc-configuring-address-prefixes)."
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(\\/([9]|[12][0-9]))$", var.secondary_cidr_block))
    error_message = "Our Automation supports only a single AZ to deploy resources. Provide a Secondary CIDR range of address prefix."
  }
}

variable "secondary_candidate_cidr_block" {
  type        = string
  default     = "10.30.0.0/24"
  description = "IBM Cloud VPC address prefixes that are needed for VPC creation. Provide a CIDR address prefix for Secondary Candidate VPC creation. For more information, see [Bring your own subnet](https://cloud.ibm.com/docs/vpc?topic=vpc-configuring-address-prefixes)."
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(\\/([9]|[12][0-9]))$", var.secondary_candidate_cidr_block))
    error_message = "Our Automation supports only a single AZ to deploy resources. Provide a Secondary Candidate CIDR range of address prefix."
  }
}