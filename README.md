Ansible playbook sensu-for-openstack.
======================================

This playbook deploys a sensu server, sensu client on all of the OSP nodes and
an uchiwa dashboard.

All the required rpms are provided with this repo allowing this playbook
to work properly at an offline customer site. Note that this set of binaries
must now be downloaded separately at:
http://file.rdu.redhat.com/~vcojot/ansible-sensu-for-openstack

The install-server can be use as sensu server and as ansible server but it is
recommended to deploy a separate RHEL 7.x instance for use as a sensu server.

It deploys some OpenStack related checks from the monitoring-for-openstack
repository and some system checks.

Please note that this playbook is a work in progress.

Please find further informations at https://mojo.redhat.com/docs/DOC-1066061

How to enable this playbook?
=========================

**1)** Clone the playbook

```
$ git clone git@gitlab.cee.redhat.com:RCIP/ansible-sensu-for-openstack.git
```

**2)** If needed, extract the binary rpms into the playbook.

This step is only needed if performing an 'offline' installation.
I.E: the OSP systems do not have access to the Internet and/or are
not registered with the RedHat CDN.

```
$ unzip -d ansible-sensu-for-openstack ./ansible-sensu-for-openstack-binaries-1.0.0-201605301301.zip 
```

How to use this playbook?
=========================

**1)** Configure hosts file. You can use a sample `inventory/hosts.sample`.
You also can use `tools/update_inventory.sh` script to generate inventory file (launch it from the undercloud).
Keep all sections headers (`[strg],[ceph]`, etc ), even if they are empty.

**2)** Configure the playbook using configuration example :

```
cp group_vars/sensu_server.sample group_vars/sensu_server
cp group_vars/all.sample group_vars/all
```

**3)** Launch ansible

```
ansible-playbook -i hosts playbook/sensu.yml
```

Some of the provided checks..
=============================

System subscription monitors CPU, memory and disk.
OpenStack API subscription monitors (from https://github.com/openstack/monitoring-for-openstack):

 - nova_instance
 - neutron_floating_ip
 - ceilometer_api
 - keystone_api
 - cinder_volume
 - nova_api
 - glance_upload
 - glance_image_exists
 - cinder_api
 - glance_api
 - neutron_api


