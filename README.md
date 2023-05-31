# hpc-cluster-symphony multicluster
Repository for the HPC Symphony Multi Cluster implementation files.

# Deployment with Schematics CLI on IBM Cloud

Initial configuration:

```
$ cp sample/config/hpc_smc_workspace_config.json config.json
$ ibmcloud iam api-key-create my-api-key --file ~/.ibm-api-key.json -d "my api key"
$ cat ~/.ibm-api-key.json | jq -r ."apikey"
# copy your apikey
$ vim config.json
# Paste your API key for SMC setup
```


You also need to generate github token if you use private Github repository.

Deployment:

```
$ ibmcloud schematics workspace new -f config.json --github-token xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
$ ibmcloud schematics workspace list
Name                               ID                                          Description         Status               Frozen
hpcc-symphony-multicluster-test       us-east.workspace.hpcc-symphony-multicluster-test.7cbc3f6b                     INACTIVE   False
OK
$ ibmcloud schematics apply --id us-east.workspace.hpcc-symphony-multicluster-test.7cbc3f6b
Do you really want to perform this action? [y/N]> y
Activity ID b0a909030f071f51d6ceb48b62ee1671
OK
$ ibmcloud schematics logs --id us-east.workspace.hpcc-symphony-multicluster-test.7cbc3f6b
...
 2023/03/29 12:20:02 Terraform refresh | Outputs:
 2023/03/29 12:20:02 Terraform refresh | 
 2023/03/29 12:20:02 Terraform refresh | primary_dns_server_ip = "10.10.0.4"
 2023/03/29 12:20:02 Terraform refresh | primary_host_domain_name = "hpc-smc-primary.smc.ibmhpc.com"
 2023/03/29 12:20:02 Terraform refresh | primary_region_name = "us-east"
 2023/03/29 12:20:02 Terraform refresh | secondary_candidate_dns_server_ip = "10.30.0.4"
 2023/03/29 12:20:02 Terraform refresh | secondary_candidate_host_domain_name = "hpc-smc-secondary-candidate.smc.ibmhpc.com"
  2023/03/29 12:20:02 Terraform refresh | secondary_dns_server_ip = "10.20.0.4"
 2023/03/29 12:20:02 Terraform refresh | secondary_host_domain_name = "hpc-smc-secondary.smc.ibmhpc.com"
 2023/03/29 12:20:02 Terraform refresh | smc_web_console = "https://localhost:8443/platform"
 2023/03/29 12:20:02 Terraform refresh | ssh_command = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -L 8443:localhost:8443 -J ubuntu@169.63.102.28 root@10.10.0.5"
 2023/03/29 12:20:02 Command finished successfully.
OK
$ ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@169.63.102.28
$ ibmcloud schematics destroy --id us-east.workspace.hpcc-symphony-multicluster-test.7cbc3f6b
```

# Deployment with Schematics UI on IBM Cloud
### Steps to setup Lone Symphony Cluster
Note : While provisioning lone symphony clusters, the cidr blocks and cluster_id should be unique for each lone symphony clusters.

 - Deploy 3 lone(symphony) clusters in different regions referring below readme file
 https://github.ibm.com/workload-eng-services/hpc-cluster-symphony/blob/ga-release/README.md


### Steps to setup SMC Cluster
SMC deployment supports the following:
- Single zone ie, ["us-east-1"]
- Multiple zones ie, ["au-syd-3","eu-de-1"] or ["us-east-1","ca-tor-3","jp-tok-3"]

1. Go to <https://cloud.ibm.com/schematics/workspaces> and create a workspace using Schematics
2. To create a workspace, you need to enter the GitHub repository URL and provide the SSH token for accessing the repository. Additionally, select Terraform version 1.0 or above and click "Next". Afterward, enter the name of the workspace and click "Next" again. Finally, click "Create" to complete the process.
3. Go to Schematic Workspace Settings, under variable section, click on "burger icons" to update the following parameters:
    - The ssh_key_name variable, which should contain your IBM Cloud SSH key, must have a unique name across all regions with same name, such as "smc-ssh-key".
    - Set the api_key variable to the API key value and mark it as sensitive in order to hide the API key in the IBM Cloud Console
    - Update cluster_prefix value to the specific hostPrefix for your Symphony multicluster.
4. Click on "Generate Plan" and ensure there are no errors and fix the errors if there are any
5. After "Generate Plan" gives no errors, click on "Apply Plan" to create resources.
6. Check the "Jobs" section on the left hand side to view the resource creation progress.
7. Check the log to see if the "Apply Plan" activity was successful. Then, copy the SSH command output to your laptop terminal and use it to SSH to the primary node through the jump host public IP, in order to SSH into one of the nodes
8. Use the public IP address of the jump host and modify the IP address of the target node to enable access to specific hosts through the jump host

#### NOTE: After provisioning the SMC cluster, wait 10 minutes before attempting to connect to the secondary host as the host data needs to be copied (rsync) from the primary system. The configuration uses the primary SMC host.

### Steps to make connection between Lone Symphony and SMC Cluster
1. Once the Lone Symphony cluster is provisioned, need to allow traffic between the SMC cluster and the Lone symphony cluster by adding the SMC CIDR block to the Security Group of all Lone symphony clusters.
2. While provisioning the SMC cluster, if you pass the parameters existing_lone_vpc and existing_lone_vpc_region, you don't need to add the Lone symphony VPC to the SMC Transit Gateway. Otherwise, you need to manually add the Lone symphony VPCs to the SMC Transit Gateway to establish the connection.
3. On DNS Zones add forwarding rule of lone symphony clusters to SMC and SMC to lone symphony by adding rule with domain_name and dns_server_ip respectively. Also add forwarding rule with each lone symphony cluster to make traffic between lone symphony clusters.
4. After completing steps 1 to 3, verify the connection by pinging the host names of the SMC and Lone symphony clusters from each other.

### Steps to setup SMCP Service in Lone Symphony Cluster
* Log in to the primary host of lone symphony using the ssh_command value as shown in the bottom of the Lone Symphony Cluster log output.
```
# ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -L 18443:localhost:8443 -J root@149.81.166.184 root@10.241.0.6
```
* Change the directory
```
# cd /tmp
```
* Login as Admin
```
# egosh user logon -u Admin -x Admin
```
* Generate SMCP xml file
```
# egosh service view SMCP -p
```
* Edit SMCP xml file to make proxy into listen mode, so this will expecting inbound connection
```
# vi SMCP.xml
```
* After SMCP.xml file opens in editor, replace MANUAL with AUTOMATIC in <sc:ControlPolicy> block and add environmental variable in second block of <sc:ActivityDescription> as <ego:EnvironmentVariable name="SMC_PROXY_INBOUND_CONNECTION">Y</ego:EnvironmentVariable> 
```
<?xml version="1.0" encoding="UTF-8"?>
<sc:ServiceDefinition xmlns:sc="http://www.platform.com/ego/2005/05/schema/sc" xmlns:ego="http://www.platform.com/ego/2005/05/schema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xsi:schemaLocation="http://www.platform.com/ego/2005/05/schema/sc ../sc.xsd http://www.platform.com/ego/2005/05/schema ../ego.xsd" ServiceName="SMCP">
  <sc:Version>1.2</sc:Version>
  <sc:Description>SMC: Proxy</sc:Description>
  <sc:MinInstances>1</sc:MinInstances>
  <sc:MaxInstances>1</sc:MaxInstances>
  <sc:Priority>10</sc:Priority>
  <sc:MaxInstancesPerSlot>1</sc:MaxInstancesPerSlot>
  <sc:NeedCredential>TRUE</sc:NeedCredential>
  <sc:ControlPolicy>
    <sc:StartType>AUTOMATIC</sc:StartType>
    <sc:MaxRestarts>10</sc:MaxRestarts>
    <sc:HostFailoverInterval>PT1S</sc:HostFailoverInterval>
  </sc:ControlPolicy>
  <sc:AllocationSpecification>
    <ego:ConsumerID>/ManagementServices/EGOManagementServices</ego:ConsumerID>
    <!--The ResourceType specifies a "compute element" identified by the URI used below-->
    <sc:ResourceSpecification ResourceType="http://www.platform.com/ego/2005/05/schema/ce">
      <ego:ResourceGroupName>ManagementHosts</ego:ResourceGroupName>
    </sc:ResourceSpecification>
  </sc:AllocationSpecification>
  <sc:ActivityDescription>
    <ego:Attribute name="hostType" type="xsd:string">LINUX86</ego:Attribute>
    <ego:ActivitySpecification>
      <ego:Command>${EGO_TOP}/soam/7.3.2/linux-x86/etc/smcproxy</ego:Command>
      <ego:ExecutionUser>egoadmin</ego:ExecutionUser>
      <ego:EnvironmentVariable name="SMC_HOME">${EGO_TOP}/soam</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="SOAM_HOME">${EGO_TOP}/soam</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="SMC_AGENT_TOP">${EGO_TOP}/soam/agent</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="SMC_KD_MASTER_LIST">@SMC_MASTER_LIST@</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="SMC_KD_PORT">@SMC_KD_PORT@</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="PATH">${EGO_TOP}/soam/7.3.2/linux-x86/lib;${EGO_LIBDIR}</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="SMC_PROXY_IDL_PORT">0</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="SMC_PLUGIN_REPORT_INTERVAL">60</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="WORKLOAD_SMC_PLUGIN_REPORT_INTERVAL">5</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="SMC_AGENT_MAX_LOG_PER_HOST">60</ego:EnvironmentVariable>
      <ego:WorkingDirectory>${EGO_CONFDIR}/../../soam/work</ego:WorkingDirectory>
      <ego:Umask>0022</ego:Umask>
      <ego:Rlimit name="NOFILE" type="soft">6400</ego:Rlimit>
    </ego:ActivitySpecification>
  </sc:ActivityDescription>
  <sc:ActivityDescription>
    <ego:Attribute name="hostType" type="xsd:string">X86_64</ego:Attribute>
    <ego:ActivitySpecification>
      <ego:Command>${EGO_TOP}/soam/7.3.2/linux-x86_64/etc/smcproxy</ego:Command>
      <ego:ExecutionUser>egoadmin</ego:ExecutionUser>
      <ego:EnvironmentVariable name="SMC_HOME">${EGO_TOP}/soam</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="SOAM_HOME">${EGO_TOP}/soam</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="SMC_AGENT_TOP">${EGO_TOP}/soam/agent</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="SMC_KD_MASTER_LIST">@SMC_MASTER_LIST@</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="SMC_KD_PORT">@SMC_KD_PORT@</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="PATH">${EGO_TOP}/soam/7.3.2/linux-x86_64/lib;${EGO_LIBDIR}</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="SMC_PROXY_IDL_PORT">0</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="SMC_PLUGIN_REPORT_INTERVAL">60</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="WORKLOAD_SMC_PLUGIN_REPORT_INTERVAL">5</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="SMC_AGENT_MAX_LOG_PER_HOST">60</ego:EnvironmentVariable>
      <ego:EnvironmentVariable name="SMC_PROXY_INBOUND_CONNECTION">Y</ego:EnvironmentVariable> 
      <ego:WorkingDirectory>${EGO_CONFDIR}/../../soam/work</ego:WorkingDirectory>
      <ego:Umask>0022</ego:Umask>
      <ego:Rlimit name="NOFILE" type="soft">12800</ego:Rlimit>
    </ego:ActivitySpecification>
  </sc:ActivityDescription>
</sc:ServiceDefinition> 
```
* Modify SMCP config file
```
# egosh service modify SMCP -f SMCP.xml
```
* Start the SMCP Service
```
# egosh service start SMCP
```
* To check SMCP Service started state
```
# egosh service list -ll | grep SMCP
```
* To check status of SMCP Service, whether proxy inbound rule connection active
```
# egosh service view | grep SMC
```

### Steps to Setup SMC to add Lone Symphony clusters to participate in Policy
#### 1. Steps to add Lone Symphony to SMC
* Log in to the primary host of SMC using the ssh_command value as shown in the bottom of the Lone Symphony Cluster log output.
```
# ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -L 8443:localhost:8443 -J ubuntu@169.63.102.28 root@10.10.0.5
```
* Login as Admin
```
# egosh user logon -u Admin -x Admin
```
* To add a lone symphony cluster to SMC, repeat the same steps for each additional lone symphony cluster you want to add. Keep in mind that "lone_name" is simply a placeholder for the name of the cluster you are adding, and it can be anything, not necessarily the name used during provisioning. Once the lone symphony cluster is added, verify its status in the SMC list. The status should be "OK" with the lone symphony cluster's ID replacing its name. If there is an error, you will see the lone_name with a status of "ERROR."
```
# smcadmin cluster add -c lone_name -p 17870 -m "hpc-lone-primary-0.dnsworker.com,hpc-lone-secondary-0.dnsworker.com"
```
* To verify whether the lone symphony cluster has been added to the SMC list, check the status. If there were no errors while adding the lone symphony cluster, you will see the status as "OK" with the lone symphony cluster ID replacing the lone name. Otherwise, you will see the lone name with a status of "ERROR".
```
# smcadmin cluster list
```
* To make Lone Symphony clusters as member of SMC. 
```
# smcadmin cluster join -c <lone_cluster_id>
```
* To view joined Lone Symphony clusters details with SMC.
```
# smcadmin cluster view
```
2. #### Steps to setup Workload Policy Configuration on SMC
* Tested Workload Policies available in [github](https://github.ibm.com/workload-eng-services/hpc-cluster-symphony-smc/tree/ga-release/resources/ibmcloud/compute/smc_vsi/smc_policy) for reference
* Workload Policy templates available in below directory of SMC host
```
# cd /data/<cluster_id>/sym732/multicluster/smc/conf/templates/
```
* Create SMC policy for workload execution
```
# smcadmin policy create -r RoundRobinPolicy.xml
```
* To view policy list and note the policy id for above created policy
```
# smcadmin policy list
```
3. #### Configuring workload placement and assign symping7.3.2 application to SMC policy
* Select the application symping7.3.2 to be assigned to SMC policy id 2 (round robin)
```
# smcadmin app addplacement -a symping7.3.2 -i 2
```
* To check policy assigned to application
```
# smcadmin policy list
```
* Add all the Lone Symphony cluster which were added with SMC to participate in Global Workload Placement
```
smcadmin cluster addplacement -c <lone_cluster_id>
```
* To list Workload Placement and check whether all Lone Symphony clusters added in Global Workload Placement
```
smcadmin cluster listplacement
```
* To validate policy by using evaluate
```
smcadmin policy evaluate -i 2 -a symping7.3.2
```

### Steps to validate SMC policy on Lone (symphony)

* Login to the lone (symphony) of primary as shown in lone (symphony) ssh_command output
```
# ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -L 8443:localhost:8443 -J root@52.116.122.64 root@10.241.0.6
```
* Set smc_global_placement to enable jobs scheduling obtained from smc
```
# export SMC_GLOBAL_PLACEMENT=enabled
```
* Set master cluster url
```
# export SMC_MASTER_CLUSTER_URL="master_list://hpc-smc-primary.smc.ibmhpc.com:17870 hpc-smc-secondary.smc.ibmhpc.com:17870 hpc-smc-secondary-candidate.smc.ibmhpc.com:17870"
```
* Validate SMC policy by executing jobs, scheduled jobs should follow the policy 
```
# symping
```

### Steps to validate failover on SMC

* Log in to the primary host using the ssh_command value as shown in the bottom of the log output.
```
# ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -L 8443:localhost:8443 -J ubuntu@169.63.102.28 root@10.10.0.5
```
* Login as Admin
```
# egosh user logon -u Admin -x Admin
```
* Check the primary host
```
# egosh resource list -m
```
* Stop EGO at primary
```
# systemctl stop ego
```
* Login to the secondary and wait for a while
```
# ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -L 8443:localhost:8443 -J ubuntu@52.116.122.64 root@10.20.0.5
```
* Check the master host name and make sure it target to secondary host as master
```
# egosh ego info
# egosh resource list -m
```
* Log into the primary host to initiate a restart of EGO.
```
# systemctl start ego
```
* Check the master host name and make sure it target to primary host as master
```
# egosh ego info
# egosh resource list -m
```

### Steps to access the SMC GUI
* Open a new command line terminal.
* Log in to the primary host using the ssh_command value as shown in the bottom of the log output.
```
# ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -L 8443:localhost:8443 -J ubuntu@52.116.122.64 root@10.10.0.5
```
* Open a browser on the local machine, and navigate to https://localhost:8443/platform. When you access this URL for the first time, your browser will display an SSL self-assigned certificate warning.
* To log in and access the SMC GUI for the cluster, use "Admin" as the login credentials for both the username and password.

# Terraform Documentation
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_http"></a> [http](#requirement\_http) | 3.0.1 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | 1.53.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_ibm"></a> [ibm](#provider\_ibm) | 1.53.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.4.0 |
| <a name="provider_template"></a> [template](#provider\_template) | 2.2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion_attach_fip"></a> [bastion\_attach\_fip](#module\_bastion\_attach\_fip) | ./resources/ibmcloud/network/floating_ip | n/a |
| <a name="module_bastion_image"></a> [bastion\_image](#module\_bastion\_image) | ./resources/ibmcloud/compute/image_check | n/a |
| <a name="module_bastion_vsi"></a> [bastion\_vsi](#module\_bastion\_vsi) | ./resources/ibmcloud/compute/bastion_vsi | n/a |
| <a name="module_dns_zone"></a> [dns\_zone](#module\_dns\_zone) | ./resources/ibmcloud/network/dns_zone | n/a |
| <a name="module_login_address_prefix"></a> [login\_address\_prefix](#module\_login\_address\_prefix) | ./resources/ibmcloud/network/vpc_address_prefix | n/a |
| <a name="module_login_security_group"></a> [login\_security\_group](#module\_login\_security\_group) | ./resources/ibmcloud/security/security_group | n/a |
| <a name="module_login_sg_inbound_rule"></a> [login\_sg\_inbound\_rule](#module\_login\_sg\_inbound\_rule) | ./resources/ibmcloud/security/security_ssh_rule | n/a |
| <a name="module_login_sg_outbound_rule"></a> [login\_sg\_outbound\_rule](#module\_login\_sg\_outbound\_rule) | ./resources/ibmcloud/security/security_rule | n/a |
| <a name="module_login_subnet"></a> [login\_subnet](#module\_login\_subnet) | ./resources/ibmcloud/network/login_subnet | n/a |
| <a name="module_lone_1_existing_vpc"></a> [lone\_1\_existing\_vpc](#module\_lone\_1\_existing\_vpc) | ./resources/ibmcloud/compute/existing_vpc | n/a |
| <a name="module_lone_2_existing_vpc"></a> [lone\_2\_existing\_vpc](#module\_lone\_2\_existing\_vpc) | ./resources/ibmcloud/compute/existing_vpc | n/a |
| <a name="module_lone_3_existing_vpc"></a> [lone\_3\_existing\_vpc](#module\_lone\_3\_existing\_vpc) | ./resources/ibmcloud/compute/existing_vpc | n/a |
| <a name="module_primary_dns_custom_resolver"></a> [primary\_dns\_custom\_resolver](#module\_primary\_dns\_custom\_resolver) | ./resources/ibmcloud/network/dns_custom_resolver | n/a |
| <a name="module_primary_dns_permitted_network"></a> [primary\_dns\_permitted\_network](#module\_primary\_dns\_permitted\_network) | ./resources/ibmcloud/network/dns_permitted_network | n/a |
| <a name="module_primary_public_gw"></a> [primary\_public\_gw](#module\_primary\_public\_gw) | ./resources/ibmcloud/network/public_gw | n/a |
| <a name="module_primary_security_group"></a> [primary\_security\_group](#module\_primary\_security\_group) | ./resources/ibmcloud/security/security_group | n/a |
| <a name="module_primary_sg_inbound_rule"></a> [primary\_sg\_inbound\_rule](#module\_primary\_sg\_inbound\_rule) | ./resources/ibmcloud/security/security_rule | n/a |
| <a name="module_primary_sg_outbound_rule"></a> [primary\_sg\_outbound\_rule](#module\_primary\_sg\_outbound\_rule) | ./resources/ibmcloud/security/security_rule | n/a |
| <a name="module_primary_smc"></a> [primary\_smc](#module\_primary\_smc) | ./resources/ibmcloud/compute/smc_vsi | n/a |
| <a name="module_primary_smc_image_check"></a> [primary\_smc\_image\_check](#module\_primary\_smc\_image\_check) | ./resources/ibmcloud/compute/image_check | n/a |
| <a name="module_primary_ssh_key"></a> [primary\_ssh\_key](#module\_primary\_ssh\_key) | ./resources/ibmcloud/compute/ssh_key | n/a |
| <a name="module_primary_subnet"></a> [primary\_subnet](#module\_primary\_subnet) | ./resources/ibmcloud/network/subnet | n/a |
| <a name="module_primary_vpc"></a> [primary\_vpc](#module\_primary\_vpc) | ./resources/ibmcloud/network/vpc | n/a |
| <a name="module_primary_vpc_address_prefix"></a> [primary\_vpc\_address\_prefix](#module\_primary\_vpc\_address\_prefix) | ./resources/ibmcloud/network/vpc_address_prefix | n/a |
| <a name="module_proxy_ssh_keys"></a> [proxy\_ssh\_keys](#module\_proxy\_ssh\_keys) | ./resources/common/generate_sshkey | n/a |
| <a name="module_secondary_candidate_dns_custom_resolver"></a> [secondary\_candidate\_dns\_custom\_resolver](#module\_secondary\_candidate\_dns\_custom\_resolver) | ./resources/ibmcloud/network/dns_custom_resolver | n/a |
| <a name="module_secondary_candidate_dns_permitted_network"></a> [secondary\_candidate\_dns\_permitted\_network](#module\_secondary\_candidate\_dns\_permitted\_network) | ./resources/ibmcloud/network/dns_permitted_network | n/a |
| <a name="module_secondary_candidate_public_gw"></a> [secondary\_candidate\_public\_gw](#module\_secondary\_candidate\_public\_gw) | ./resources/ibmcloud/network/public_gw | n/a |
| <a name="module_secondary_candidate_security_group"></a> [secondary\_candidate\_security\_group](#module\_secondary\_candidate\_security\_group) | ./resources/ibmcloud/security/security_group | n/a |
| <a name="module_secondary_candidate_sg_inbound_rule"></a> [secondary\_candidate\_sg\_inbound\_rule](#module\_secondary\_candidate\_sg\_inbound\_rule) | ./resources/ibmcloud/security/security_rule | n/a |
| <a name="module_secondary_candidate_sg_outbound_rule"></a> [secondary\_candidate\_sg\_outbound\_rule](#module\_secondary\_candidate\_sg\_outbound\_rule) | ./resources/ibmcloud/security/security_rule | n/a |
| <a name="module_secondary_candidate_smc"></a> [secondary\_candidate\_smc](#module\_secondary\_candidate\_smc) | ./resources/ibmcloud/compute/smc_vsi | n/a |
| <a name="module_secondary_candidate_smc_image_check"></a> [secondary\_candidate\_smc\_image\_check](#module\_secondary\_candidate\_smc\_image\_check) | ./resources/ibmcloud/compute/image_check | n/a |
| <a name="module_secondary_candidate_ssh_key"></a> [secondary\_candidate\_ssh\_key](#module\_secondary\_candidate\_ssh\_key) | ./resources/ibmcloud/compute/ssh_key | n/a |
| <a name="module_secondary_candidate_subnet"></a> [secondary\_candidate\_subnet](#module\_secondary\_candidate\_subnet) | ./resources/ibmcloud/network/subnet | n/a |
| <a name="module_secondary_candidate_vpc"></a> [secondary\_candidate\_vpc](#module\_secondary\_candidate\_vpc) | ./resources/ibmcloud/network/vpc | n/a |
| <a name="module_secondary_candidate_vpc_address_prefix"></a> [secondary\_candidate\_vpc\_address\_prefix](#module\_secondary\_candidate\_vpc\_address\_prefix) | ./resources/ibmcloud/network/vpc_address_prefix | n/a |
| <a name="module_secondary_dns_custom_resolver"></a> [secondary\_dns\_custom\_resolver](#module\_secondary\_dns\_custom\_resolver) | ./resources/ibmcloud/network/dns_custom_resolver | n/a |
| <a name="module_secondary_dns_permitted_network"></a> [secondary\_dns\_permitted\_network](#module\_secondary\_dns\_permitted\_network) | ./resources/ibmcloud/network/dns_permitted_network | n/a |
| <a name="module_secondary_public_gw"></a> [secondary\_public\_gw](#module\_secondary\_public\_gw) | ./resources/ibmcloud/network/public_gw | n/a |
| <a name="module_secondary_security_group"></a> [secondary\_security\_group](#module\_secondary\_security\_group) | ./resources/ibmcloud/security/security_group | n/a |
| <a name="module_secondary_sg_inbound_rule"></a> [secondary\_sg\_inbound\_rule](#module\_secondary\_sg\_inbound\_rule) | ./resources/ibmcloud/security/security_rule | n/a |
| <a name="module_secondary_sg_outbound_rule"></a> [secondary\_sg\_outbound\_rule](#module\_secondary\_sg\_outbound\_rule) | ./resources/ibmcloud/security/security_rule | n/a |
| <a name="module_secondary_smc"></a> [secondary\_smc](#module\_secondary\_smc) | ./resources/ibmcloud/compute/smc_vsi | n/a |
| <a name="module_secondary_smc_image_check"></a> [secondary\_smc\_image\_check](#module\_secondary\_smc\_image\_check) | ./resources/ibmcloud/compute/image_check | n/a |
| <a name="module_secondary_ssh_key"></a> [secondary\_ssh\_key](#module\_secondary\_ssh\_key) | ./resources/ibmcloud/compute/ssh_key | n/a |
| <a name="module_secondary_subnet"></a> [secondary\_subnet](#module\_secondary\_subnet) | ./resources/ibmcloud/network/subnet | n/a |
| <a name="module_secondary_vpc"></a> [secondary\_vpc](#module\_secondary\_vpc) | ./resources/ibmcloud/network/vpc | n/a |
| <a name="module_secondary_vpc_address_prefix"></a> [secondary\_vpc\_address\_prefix](#module\_secondary\_vpc\_address\_prefix) | ./resources/ibmcloud/network/vpc_address_prefix | n/a |
| <a name="module_transit_gw"></a> [transit\_gw](#module\_transit\_gw) | ./resources/ibmcloud/network/transit_gw | n/a |

## Resources

| Name | Type |
|------|------|
| [ibm_is_instance_profile.bastion](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.53.0/docs/data-sources/is_instance_profile) | data source |
| [ibm_is_instance_profile.smc_profile](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.53.0/docs/data-sources/is_instance_profile) | data source |
| [ibm_is_region.primary_smc_region](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.53.0/docs/data-sources/is_region) | data source |
| [ibm_is_region.secondary_candidate_smc_region](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.53.0/docs/data-sources/is_region) | data source |
| [ibm_is_region.secondary_smc_region](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.53.0/docs/data-sources/is_region) | data source |
| [ibm_resource_group.resource_group](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.53.0/docs/data-sources/resource_group) | data source |
| [local_file.ansible_smc_data_syn](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |
| [template_file.metadata_startup_script](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.primary_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.secondary_candidate_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.secondary_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_key"></a> [api\_key](#input\_api\_key) | This is the API key for IBM Cloud account in which the Symphony Multi cluster needs to be deployed. [Learn more](https://cloud.ibm.com/docs/account?topic=account-userapikey). | `string` | n/a | yes |
| <a name="input_bastion_host_instance_type"></a> [bastion\_host\_instance\_type](#input\_bastion\_host\_instance\_type) | Specify the virtual server instance profile type name to be used to create the bastion node for the Symphony Multi Cluster. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles). | `string` | `"bx2-2x8"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | ID of the cluster used by Symphony Multi Cluster for configuration of resources. This must be up to 39 alphanumeric characters including the underscore (\_), the hyphen (-), and the period (.). Other special characters and spaces are not allowed. Do not use the name of any host or user as the name of your cluster. You cannot change it after installation. | `string` | `"HPCMultiCluster"` | no |
| <a name="input_cluster_prefix"></a> [cluster\_prefix](#input\_cluster\_prefix) | Prefix that is used to name the Symphony Multi cluster and IBM Cloud resources that are provisioned to build the Symphony Multi cluster instance. You cannot create more than one instance of the Symphony Multi cluster with the same name. Make sure that the name is unique. Enter a prefix name, such as my-hpcc. | `string` | `"hpcc-smc"` | no |
| <a name="input_dns_domain"></a> [dns\_domain](#input\_dns\_domain) | IBM Cloud DNS Services domain name to be used for the Symphony Multi Cluster host. | `string` | `"smc.ibmhpc.com"` | no |
| <a name="input_login_cidr_block"></a> [login\_cidr\_block](#input\_login\_cidr\_block) | IBM Cloud VPC address prefixes that are needed for VPC creation. Provide a CIDR address prefix for VPC creation. For more information, see [Bring your own subnet](https://cloud.ibm.com/docs/vpc?topic=vpc-configuring-address-prefixes). | `list(string)` | <pre>[<br>  "10.10.4.0/28"<br>]</pre> | no |
| <a name="input_lone_symphony_cidr_block"></a> [lone\_symphony\_cidr\_block](#input\_lone\_symphony\_cidr\_block) | Comma-separated list of CIDR blocks which used in Spectrum Symphony Cluster(Lone Symphony Cluster). | `list(string)` | `null` | no |
| <a name="input_lone_vpc_name"></a> [lone\_vpc\_name](#input\_lone\_vpc\_name) | Name of an existing Lone Symphony VPC, lone\_vpc\_name and lone\_vpc\_region should be in same order. If no value is given, then need to add existing\_lone\_vpc manually with SMC transit\_gateway. Note: lone\_vpc\_name support maximum of 3 existing\_lone\_vpc\_name. [Learn more](https://cloud.ibm.com/docs/vpc). | `list(string)` | `null` | no |
| <a name="input_lone_vpc_region"></a> [lone\_vpc\_region](#input\_lone\_vpc\_region) | Name of the IBM Cloud region where the existing Lone Symphony VPC, lone\_vpc\_name and lone\_vpc\_region should be in same order (Examples: us-east, us-south, etc.). Note: lone\_vpc\_region support maximum of 3 existing\_lone\_vpc\_region. For more information, see [Region and data center locations for resource deployment](https://cloud.ibm.com/docs/overview?topic=overview-locations). | `list(string)` | `null` | no |
| <a name="input_primary_cidr_block"></a> [primary\_cidr\_block](#input\_primary\_cidr\_block) | IBM Cloud VPC address prefixes that are needed for VPC creation. Provide a CIDR address prefix for Primary VPC creation. For more information, see [Bring your own subnet](https://cloud.ibm.com/docs/vpc?topic=vpc-configuring-address-prefixes). | `string` | `"10.10.0.0/24"` | no |
| <a name="input_remote_allowed_ips"></a> [remote\_allowed\_ips](#input\_remote\_allowed\_ips) | Comma-separated list of IP addresses that can access the Symphony Multi Cluster instance through an SSH interface. For security purposes, provide the public IP addresses assigned to the devices that are authorized to establish SSH connections (for example, ["169.45.117.34"]). To fetch the IP address of the device, use https://ipv4.icanhazip.com/. | `list(string)` | n/a | yes |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | Resource group name from your IBM Cloud account where the VPC resources should be deployed. [Learn more](https://cloud.ibm.com/docs/account?topic=account-rgs). | `string` | `"Default"` | no |
| <a name="input_secondary_candidate_cidr_block"></a> [secondary\_candidate\_cidr\_block](#input\_secondary\_candidate\_cidr\_block) | IBM Cloud VPC address prefixes that are needed for VPC creation. Provide a CIDR address prefix for Secondary Candidate VPC creation. For more information, see [Bring your own subnet](https://cloud.ibm.com/docs/vpc?topic=vpc-configuring-address-prefixes). | `string` | `"10.30.0.0/24"` | no |
| <a name="input_secondary_cidr_block"></a> [secondary\_cidr\_block](#input\_secondary\_cidr\_block) | IBM Cloud VPC address prefixes that are needed for VPC creation. Provide a CIDR address prefix for Secondary VPC creation. For more information, see [Bring your own subnet](https://cloud.ibm.com/docs/vpc?topic=vpc-configuring-address-prefixes). | `string` | `"10.20.0.0/24"` | no |
| <a name="input_smc_host_instance_type"></a> [smc\_host\_instance\_type](#input\_smc\_host\_instance\_type) | Specify the virtual server instance profile type name to be used to create the Symphony Multi Cluster host. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-profiles). | `string` | `"bx2-4x16"` | no |
| <a name="input_smc_image_name"></a> [smc\_image\_name](#input\_smc\_image\_name) | Name of the custom image that you want to use to create virtual server instances in your IBM Cloud account to deploy the IBM Symphony Multi Cluster. By default, the automation uses a base image with additional software packages mentioned [here](https://cloud.ibm.com/docs/hpc-spectrum-symphony#create-custom-image). If you would like to include your application-specific binary files, follow the instructions in [ Planning for custom images ](https://cloud.ibm.com/docs/vpc?topic=vpc-planning-custom-images) to create your own custom image and use that to build the IBM Symphony cluster through this offering. | `string` | `"hpcc-symphony732-rhel86-smc-v1"` | no |
| <a name="input_smc_zone"></a> [smc\_zone](#input\_smc\_zone) | IBM Cloud zone name within the selected region where the Symphony Multi Cluster resources should be deployed. Note: smc\_zone support maximum of 3 zone. Examples as ["us-south-1","eu-gb-3","jp-tok-2"] or ["us-south-1","us-south-1","us-south-3"] or ["jp-tok-3","au-syd-3"] or ["jp-tok-2"]. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-creating-a-vpc-in-a-different-region#get-zones-using-the-cli). | `list(string)` | n/a | yes |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Comma-separated list of names of the SSH key configured in your IBM Cloud account that is used to establish a connection to the Symphony resources SMC vsi. NOTE: SSH key-name should be unique in all region with same name. Ensure the SSH key is present in the same resource group and region where the cluster is being provisioned. If you do not have an SSH key in your IBM Cloud account, create one by using the instructions given here. [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-ssh-keys). | `string` | n/a | yes |
| <a name="input_sym_license_confirmation"></a> [sym\_license\_confirmation](#input\_sym\_license\_confirmation) | Confirm your use of IBM Symphony Multi Cluster licenses. By entering 'true' for the property you have agreed to one of the two conditions. 1. You are using the software in production and confirm you have sufficient licenses to cover your use under the International Program License Agreement (IPLA). 2. You are evaluating the software and agree to abide by the International License Agreement for Evaluation of Programs (ILAE). NOTE: Failure to comply with licenses for production use of software is a violation of IBM International Program License Agreement. [Learn more](https://www.ibm.com/software/passportadvantage/programlicense.html). | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_primary_dns_server_ip"></a> [primary\_dns\_server\_ip](#output\_primary\_dns\_server\_ip) | SMC primary domain name server IP |
| <a name="output_primary_host_name"></a> [primary\_host\_name](#output\_primary\_host\_name) | Primary SMC host domain name |
| <a name="output_primary_region_name"></a> [primary\_region\_name](#output\_primary\_region\_name) | Region for Primary SMC host |
| <a name="output_secondary_candidate_dns_server_ip"></a> [secondary\_candidate\_dns\_server\_ip](#output\_secondary\_candidate\_dns\_server\_ip) | SMC secondary\_candidate domain name server IP |
| <a name="output_secondary_candidate_host_name"></a> [secondary\_candidate\_host\_name](#output\_secondary\_candidate\_host\_name) | Secondary-Candidate SMC host domain name |
| <a name="output_secondary_candidate_region_name"></a> [secondary\_candidate\_region\_name](#output\_secondary\_candidate\_region\_name) | Region for Secondary-Candidate SMC host |
| <a name="output_secondary_dns_server_ip"></a> [secondary\_dns\_server\_ip](#output\_secondary\_dns\_server\_ip) | SMC secondary domain name server IP |
| <a name="output_secondary_host_name"></a> [secondary\_host\_name](#output\_secondary\_host\_name) | Secondary SMC host domain name |
| <a name="output_secondary_region_name"></a> [secondary\_region\_name](#output\_secondary\_region\_name) | Region for Secondary SMC host |
| <a name="output_smc_web_console"></a> [smc\_web\_console](#output\_smc\_web\_console) | SMC web console will be available with this url, after login with ssh command with tunneling |
| <a name="output_ssh_command"></a> [ssh\_command](#output\_ssh\_command) | SSH command that can be used to login to bastion host to manage the cluster, also enables webconsole with tunneling. |
