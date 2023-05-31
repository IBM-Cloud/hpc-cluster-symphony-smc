#!/usr/bin/bash

###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

logfile=/tmp/user_data.log
echo START `date '+%Y-%m-%d %H:%M:%S'`

#
# Export user data, which is defined with the "UserData" attribute
# in the template
#
%EXPORT_USER_DATA%

#input parameters
cluster_name="${cluster_id}"
smcHostRole="${smc_host_role}"
cluster_cidr="${cluster_cidr}"
cluster_prefix="${cluster_prefix}"
domainName="${dns_domain}"
smc_zone_length=${smc_zone_length}


#writing files
echo "${ssh_private_key}" > /tmp/ssh_private_key
echo "${ssh_public_key}" > /tmp/ssh_public_key
echo "${ansible_smc_data_syn}" > /etc/ansible/data_sync.yml


