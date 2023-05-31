#!/bin/bash

###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

set -x
##################################################################
#args

#host can be primary, secondary, management_node or not set for compute
export smcHostRole=${smcHostRole}

#cluster ID should be 39 characters alphanumeric no spaces, supports -_.
export clusterID=${cluster_name}

#cluster prefix should be 39 characters alphanumeric no spaces, supports -_.
export clusterPrefix=${cluster_prefix}

#mtu9000
export CLUSTER_CIDR=${cluster_cidr}

#smc zone length
export smc_zone_length=${smc_zone_length}

#password should be 8 to 15 characters
export adminPswd=Admin
export guestPswd=Guest

export domainName=${domainName}
export CLUSTERNAME=${clusterID}
export CLUSTERADMIN=egoadmin
export EGO_TOP=/opt/ibm/spectrumcomputing/symphony/multicluster
export SHARED_TOP=/data
export SHARED_TOP_CLUSTERID=${SHARED_TOP}/${clusterID}
export HOSTS_FILES=${SHARED_TOP_CLUSTERID}/hosts
export SYMPHONY_VERSION=sym732
export SHARED_TOP_SYM=${SHARED_TOP_CLUSTERID}/${SYMPHONY_VERSION}/multicluster
export HOST_NAME=$(hostname).$domainName
export SMC_PRIMARY_HOST_NAME=${clusterPrefix}-primary.${domainName}
export SMC_SECONDARY_HOST_NAME=${clusterPrefix}-secondary.${domainName}
export SMC_SECONDARY_CANDIDATE_HOST_NAME=${clusterPrefix}-secondary-candidate.${domainName}
export HOST_IP=$(hostname -I)
export MAX_RETRIES=200
export DELAY=15
export STARTUP_DELAY=1
export ENTITLEMENT_FILE=$EGO_TOP/sym_adv_entitlement.dat
export EGO_HOSTS_FILE=${SHARED_TOP_SYM}/kernel/conf/hosts
export SHARED_EGO_CONF_FILE=${SHARED_TOP_SYM}/kernel/conf/ego.conf
export SHARED_EGO_CLUSTER_CONF_FILE=${SHARED_TOP_SYM}/kernel/conf/ego.cluster.${clusterID}
export ANSIBLE_SMC_DATA_SYN="/etc/ansible/data_sync.yml"



function mount_data_volume
{
    found=0
    fstype="ext4"
    while [ $found -eq 0 ]; do
        for vdx in `lsblk -d -n --output NAME`; do
            desc=$(file -s /dev/$vdx | grep ': data$' | cut -d : -f1)
            if [ "$desc" != "" ]; then
                mkfs -t $fstype $desc
                uuid=`blkid -s UUID -o value $desc`
                echo "UUID=$uuid $SHARED_TOP $fstype defaults,noatime 0 0" >> /etc/fstab
                mkdir -p $SHARED_TOP
                mount $SHARED_TOP
                if [ $? -eq 0 ]; then
                  echo "mount /data completed" >> $logfile
                else
                  echo "mount /data failed" >> $logfile
                fi
                chmod 775 $SHARED_TOP
                found=1
                break
            fi
        done
        sleep 5s
    done
}

function create_smc_shared
{
    mkdir -p ${SHARED_TOP_SYM}
    chown -R ${CLUSTERADMIN} ${SHARED_TOP_CLUSTERID}
    echo "Directory create and permission" >> $logfile
}

function mtu9000
{
    #Change the MTU setting
    ip route replace $CLUSTER_CIDR dev eth0 proto kernel scope link src $HOST_IP mtu 9000
    echo 'ip route replace '$CLUSTER_CIDR' dev eth0 proto kernel scope link src '$HOST_IP' mtu 9000' >> /etc/sysconfig/network-scripts/route-eth0
    echo "mtu setting done" >> $logfile
}

function config_symprimary
{
    source ${EGO_TOP}/profile.platform

    su ${CLUSTERADMIN} -c 'egoconfig join ${SMC_PRIMARY_HOST_NAME} -f' >> $logfile
    su ${CLUSTERADMIN} -c 'egoconfig setpassword -x Admin -f'
    su ${CLUSTERADMIN} -c 'egoconfig setentitlement $ENTITLEMENT_FILE' >> $logfile
    su ${CLUSTERADMIN} -c 'egoconfig mghost ${SHARED_TOP_SYM} -f' >> $logfile
    source ${EGO_TOP}/profile.platform

    if (( ${smc_zone_length} == 3 )); then
        EGO_MASTER_LIST="${SMC_PRIMARY_HOST_NAME} ${SMC_SECONDARY_HOST_NAME} ${SMC_SECONDARY_CANDIDATE_HOST_NAME}"
        replace="${SMC_PRIMARY_HOST_NAME} !        !            -    -    -   (mg linux)\n${SMC_SECONDARY_HOST_NAME} !        !            -    -    -   (mg linux)\n${SMC_SECONDARY_CANDIDATE_HOST_NAME} !        !            -    -    -   (mg linux)"
    elif (( ${smc_zone_length} == 2 )); then
        EGO_MASTER_LIST="${SMC_PRIMARY_HOST_NAME} ${SMC_SECONDARY_HOST_NAME}"
        replace="${SMC_PRIMARY_HOST_NAME} !        !            -    -    -   (mg linux)\n${SMC_SECONDARY_HOST_NAME} !        !            -    -    -   (mg linux)"
    elif (( ${smc_zone_length} == 1 )); then
        EGO_MASTER_LIST="${SMC_PRIMARY_HOST_NAME}"
        replace="${SMC_PRIMARY_HOST_NAME} !        !            -    -    -   (mg linux)"
    fi        

    sed -i -e "s|EGO_MASTER_LIST=.*|EGO_MASTER_LIST=\"${EGO_MASTER_LIST}\"|g" ${SHARED_EGO_CONF_FILE}
    sed -i -e "s|^${HOST_NAME}.*|${replace}|g" ${SHARED_EGO_CLUSTER_CONF_FILE}

    #fix up
    mkdir -p ${SHARED_TOP_SYM}/kernel/audit && chown -R ${CLUSTERADMIN} ${SHARED_TOP_SYM}/kernel/audit
    mkdir -p ${SHARED_TOP_SYM}/kernel/work/data && chown -R ${CLUSTERADMIN} ${SHARED_TOP_SYM}/kernel/work/data

}

function is_ip_in_dns
{
    date
    nslookup $1 | awk 'BEGIN{ xit=1; } {if ($2=="name"){xit=0;}} END {exit xit}'
}

function update_hosts
{
    echo "update_hosts ${HOST_IP}: ${HOST_NAME}"
    date
    nslookup -debug ibm.com
    for (( i=1; i <= $MAX_RETRIES; ++i ))
    do
        if is_ip_in_dns ${HOST_IP}; then
             echo "ip address found: ${HOST_IP}"
             break;
        fi
        echo "waiting for $HOST_IP to be in DNS $i/$MAX_RETRIES"
        sleep ${DELAY}
    done
    nslookup -debug -querytype=hinfo ${HOST_IP}
    hostnamectl
    hostnamectl set-hostname ${HOST_NAME}
    hostname

    #Fully qualified domain name
    echo "${HOST_IP} ${HOST_NAME}" > /tmp/hosts
    mkdir -p ${HOSTS_FILES} && cp /tmp/hosts ${HOSTS_FILES}/${HOST_NAME}
    touch ${EGO_HOSTS_FILE}
    cat /tmp/hosts >> ${EGO_HOSTS_FILE}
    chown ${CLUSTERADMIN} ${EGO_HOSTS_FILE}
    chmod 644 ${EGO_HOSTS_FILE}
    rm -f /tmp/hosts
}

function config_sym_failover_service
{
    source ${EGO_TOP}/profile.platform

    search_config="<ego:ResourceRequirement>"
    replace_config="<ego:ResourceRequirement>select('$HOST_NAME')</ego:ResourceRequirement>"

    config_file1="$SHARED_TOP_SYM/eservice/esc/conf/services/smcm.xml"
    config_file2="$SHARED_TOP_SYM/eservice/esc/conf/services/gui_service.xml"
    config_file3="$SHARED_TOP_SYM/eservice/esc/conf/services/rest_service.xml"
    config_file4="$SHARED_TOP_SYM/eservice/esc/conf/services/rs.xml"

    sed -i -e "s|${search_config}.*|${replace_config}|g" ${config_file1}
    sed -i -e "s|${search_config}.*|${replace_config}|g" ${config_file2}
    sed -i -e "s|${search_config}.*|${replace_config}|g" ${config_file3}
    sed -i -e "s|${search_config}.*|${replace_config}|g" ${config_file4}

}

function config_symfailover
{
script_name="/tmp/secondary_smc_config.sh"
cat > ${script_name} <<EOF
#!/bin/bash

###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

set -x
##################################################################
  while true; do
    if [[ "\$(ls -A ${SHARED_TOP_SYM})" ]] ;then
      sleep 10m

      rsync -e "ssh -o StrictHostKeyChecking=no" -avzh root@${SMC_PRIMARY_HOST_NAME}:$SHARED_TOP_SYM/ $SHARED_TOP_SYM/
      
      source ${EGO_TOP}/profile.platform
      su ${CLUSTERADMIN} -c 'egoconfig join ${SMC_PRIMARY_HOST_NAME} -f' >> $logfile
      su ${CLUSTERADMIN} -c 'egoconfig mghost ${SHARED_TOP_SYM} -f' >> $logfile
      source ${EGO_TOP}/profile.platform
      echo "source ${EGO_TOP}/profile.platform" >> /root/.bashrc
    
      egosh service stop all >> $logfile
      sleep $STARTUP_DELAY
      egosetsudoers.sh
      egosetrc.sh
      systemctl start ego
      systemctl status ego
      sleep $STARTUP_DELAY

      sed -i -e "s|<ego:ResourceRequirement>.*|<ego:ResourceRequirement>select('$HOST_NAME')</ego:ResourceRequirement>|g" $SHARED_TOP_SYM/eservice/esc/conf/services/smcm.xml
      sed -i -e "s|<ego:ResourceRequirement>.*|<ego:ResourceRequirement>select('$HOST_NAME')</ego:ResourceRequirement>|g" $SHARED_TOP_SYM/eservice/esc/conf/services/gui_service.xml
      sed -i -e "s|<ego:ResourceRequirement>.*|<ego:ResourceRequirement>select('$HOST_NAME')</ego:ResourceRequirement>|g" $SHARED_TOP_SYM/eservice/esc/conf/services/rest_service.xml
      sed -i -e "s|<ego:ResourceRequirement>.*|<ego:ResourceRequirement>select('$HOST_NAME')</ego:ResourceRequirement>|g" $SHARED_TOP_SYM/eservice/esc/conf/services/rs.xml

      rm $script_name
      break
    else
      sleep 5s
      echo "${SHARED_TOP_SYM} empty, waiting for smc data in ${SHARED_TOP_SYM} ">> $logfile
    fi
  done
  exit 0
EOF
}

function update_clusterid
{
    #change cluster ID
    if [ "${clusterID}" != "" ]; then
        echo "Renaming cluster to ${clusterID}"
        if [ -f ${EGO_TOP}/kernel/conf/ego.cluster.IBMCloudSym732MultiCluster ]; then
            mv ${EGO_TOP}/kernel/conf/ego.cluster.IBMCloudSym732MultiCluster ${EGO_TOP}/kernel/conf/ego.cluster.${clusterID}
        fi
        if [ -f ${EGO_TOP}/kernel/conf/ego.shared ]; then
            sed -i -e "s|IBMCloudSym732MultiCluster|${clusterID}|g" ${EGO_TOP}/kernel/conf/ego.shared
        fi
    fi
}

function start_ego
{
    echo "source ${EGO_TOP}/profile.platform" >> /root/.bashrc
    egosh service stop all >> $logfile
    sleep $STARTUP_DELAY
    egosetsudoers.sh
    sleep 5
    egosetrc.sh
    sleep 5
    systemctl start ego
    systemctl status ego
    sleep $STARTUP_DELAY
}

function update_passwords
{
    for I in 1 2 3 4 5
    do
        if egosh user logon -u Admin -x Admin; then
            break;
        fi
        echo "Waiting cluster is up $I/5"
        sleep ${DELAY}
    done
    if [ "${guestPswd}" != "" ]; then
        egosh user modify -u Guest -x ${guestPswd}
    fi
    if [ "${adminPswd}" != "" ]; then
        echo y | egosh user modify -u Admin -x ${adminPswd}
    fi
    egosh user logoff
}

function configure_sshkey
{
    mv /tmp/ssh_private_key /root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa
    cat /tmp/ssh_public_key >> /root/.ssh/authorized_keys
    echo "StrictHostKeyChecking no" >> /root/.ssh/config
    rm -rf /tmp/ssh_public_key
}

function data_sync
{
  smc_data_syn_script="/usr/bin/smc_data_syn.sh"

cat > ${smc_data_syn_script} <<EOF
#!/bin/bash

###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

set -x
##################################################################

function check_primary_data_sync
{
    if ps -aux | grep -v grep | grep vemkd > /dev/null; then
      echo "[\$(date)]: Files changed in $SHARED_TOP_CLUSTERID and this is smc master host, ansible playbook will be executed."  >> $logfile
      ansible-playbook $ANSIBLE_SMC_DATA_SYN >> $logfile
      echo "[\$(date)]: Ansible playbook executed"  >> $logfile
    else
      echo "[\$(date)]: Files changed in $SHARED_TOP_CLUSTERID and this is not smc master host, ansible playbook will not be executed."  >> $logfile
    fi
}

    inotifywait -q -m -r -e modify,delete,create,move --exclude ".*(\.swp|\.swpx|\.lock|\.tmp)" $SHARED_TOP_CLUSTERID | while read DIRECTORY EVENT FILE; do
      echo "[\$(date)]: \$FILE in \$DIRECTORY \$EVENT"  >> $logfile
      check_primary_data_sync
    done
EOF
}

function data_sync_service
{
  smc_data_syn_service="/etc/systemd/system/smcdatasync.service "
cat > ${smc_data_syn_service} <<EOF
[Unit]
Name=smc-data-sync
Description=This service is used to manage SMC data sync, which sync's data to secondary host's from primary host

[Service]
Type=simple
ExecStart=/bin/bash /usr/bin/smc_data_syn.sh

[Install]
WantedBy=multi-user.target
EOF
}

function sync_smc_data_ansible_config
{
    ansible_host_file="/etc/ansible/hosts"
    ansible_config_file="/etc/ansible/ansible.cfg"
    ansible_playbook="/etc/ansible/data_sync.yml"
    if [ "${smcHostRole}" == "primary" ]; then
        echo "[smc_host]" > ${ansible_host_file}
        if (( ${smc_zone_length} == 2 )); then
        echo "${SMC_SECONDARY_HOST_NAME} ansible_ssh_user=root ansible_ssh_private_key_file=/root/.ssh/id_rsa" >> ${ansible_host_file}
        elif (( ${smc_zone_length} == 3 )); then
        echo "${SMC_SECONDARY_HOST_NAME} ansible_ssh_user=root ansible_ssh_private_key_file=/root/.ssh/id_rsa" >> ${ansible_host_file}
        echo "${SMC_SECONDARY_CANDIDATE_HOST_NAME} ansible_ssh_user=root ansible_ssh_private_key_file=/root/.ssh/id_rsa" >> ${ansible_host_file} 
        fi
        sed -i '/#host_key_checking/s/^#//g' ${ansible_config_file}
        sed -i -e "s|/data/HPCMultiCluster/sym732/multicluster/smc/.*|/data/${CLUSTERNAME}/${SYMPHONY_VERSION}/multicluster/smc/|g" ${ansible_playbook}
        sed -i -e "s|/data/HPCMultiCluster/sym732/multicluster/eservice/rs/.*|/data/${CLUSTERNAME}/${SYMPHONY_VERSION}/multicluster/eservice/rs/|g" ${ansible_playbook}

    elif [ "${smcHostRole}" == "secondary" ]; then
        echo "[smc_host]" > ${ansible_host_file} 
        if (( ${smc_zone_length} == 2 )); then
        echo "${SMC_PRIMARY_HOST_NAME} ansible_ssh_user=root ansible_ssh_private_key_file=/root/.ssh/id_rsa" >> ${ansible_host_file}
        elif (( ${smc_zone_length} == 3 )); then 
        echo "${SMC_PRIMARY_HOST_NAME} ansible_ssh_user=root ansible_ssh_private_key_file=/root/.ssh/id_rsa" >> ${ansible_host_file}
        echo "${SMC_SECONDARY_CANDIDATE_HOST_NAME} ansible_ssh_user=root ansible_ssh_private_key_file=/root/.ssh/id_rsa" >> ${ansible_host_file}
        fi
        sed -i '/#host_key_checking/s/^#//g' ${ansible_config_file}
        sed -i -e "s|/data/HPCMultiCluster/sym732/multicluster/smc/.*|/data/${CLUSTERNAME}/${SYMPHONY_VERSION}/multicluster/smc/|g" ${ansible_playbook}
        sed -i -e "s|/data/HPCMultiCluster/sym732/multicluster/eservice/rs/.*|/data/${CLUSTERNAME}/${SYMPHONY_VERSION}/multicluster/eservice/rs/|g" ${ansible_playbook}

    elif [ "${smcHostRole}" == "secondary-candidate" ]; then
        echo "[smc_host]" > /etc/ansible/hosts
        if (( ${smc_zone_length} == 3 )); then 
        echo "${SMC_PRIMARY_HOST_NAME} ansible_ssh_user=root ansible_ssh_private_key_file=/root/.ssh/id_rsa" >> ${ansible_host_file}
        echo "${SMC_SECONDARY_HOST_NAME} ansible_ssh_user=root ansible_ssh_private_key_file=/root/.ssh/id_rsa" >> ${ansible_host_file}
        fi 
        sed -i '/#host_key_checking/s/^#//g' ${ansible_config_file}
        sed -i -e "s|/data/HPCMultiCluster/sym732/multicluster/smc/.*|/data/${CLUSTERNAME}/${SYMPHONY_VERSION}/multicluster/smc/|g" ${ansible_playbook}
        sed -i -e "s|/data/HPCMultiCluster/sym732/multicluster/eservice/rs/.*|/data/${CLUSTERNAME}/${SYMPHONY_VERSION}/multicluster/eservice/rs/|g" ${ansible_playbook}
    fi
}

function change_permission_run_syn
{
    data_sync
    data_sync_service
    chmod +x /usr/bin/smc_data_syn.sh
    chmod 644 /etc/systemd/system/smcdatasync.service
    systemctl start smcdatasync
    systemctl enable smcdatasync
    if ! [ "${smcHostRole}" == "primary" ]; then
      chmod 770 /tmp/secondary_smc_config.sh
      nohup /tmp/secondary_smc_config.sh > /dev/null 2>&1 &
    fi
}

if [ "${smcHostRole}" == "primary" ]; then
    mount_data_volume
    create_smc_shared
    mtu9000
    update_hosts
    configure_sshkey
    update_clusterid
    config_symprimary
    start_ego
    update_passwords
    if (( ${smc_zone_length} > 1 )); then
        sync_smc_data_ansible_config
    fi
    change_permission_run_syn
    config_sym_failover_service
    source ${EGO_TOP}/profile.platform
else
    mount_data_volume
    create_smc_shared
    mtu9000
    update_hosts
    configure_sshkey
    update_clusterid
    config_symfailover
    sync_smc_data_ansible_config
    change_permission_run_syn
    source ${EGO_TOP}/profile.platform
fi