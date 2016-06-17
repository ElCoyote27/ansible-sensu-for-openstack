#!/bin/bash
#IMG_SRC="images/rhel-guest-image-7.2-20151102.0.x86_64.qcow2"
IMG_SRC="images/rhel-guest-image-7.2-20160302.0.x86_64.qcow2"
IMG_DST="rhel-7.2-guest-sensu.x86_64.qcow2"
IMG_TMP="_tmpdisk.qcow2"
VDI_DST="rhel-7.2-guest-sensu.x86_64.vdi"
VIRT_ARGS="--memsize 2048 --smp 4"
wantvbox=0

# requirements.
rpm -q libguestfs-tools-c || dnf install -y libguestfs-tools-c
rpm -q libguestfs-xfs || dnf install -y libguestfs-xfs
export LIBGUESTFS_BACKEND=direct

# Credentials
# if you want to temporarly set the root pass:   --root-password password:calvin
if [ -f .sm_creds ]; then
	. .sm_creds
else
	echo "NO credentials for subscription Manager found in ./.sm_creds!" ; exit 127
fi

if [ "x${SM_USER}" = "x" -o "x${SM_USER}" = "x" -o "x${SM_POOL_ID}" = "x" -o -z "${STACK_SSH_KEY}" ]; then
	echo "Something is missing in your ./.sm_creds!" ; exit 127
fi

# Copy the source image again and overwrite the destination
/bin/cp -afv ${IMG_SRC} ${IMG_DST} 

# Initial steps
# Resize to 128G
qemu-img resize ${IMG_DST} 137438953472

#
/bin/cp -afv ${IMG_DST} ${IMG_TMP}

# Expand /dev/sda so we can run xfs_growfs on it..
virt-resize --expand=/dev/sda1 ${IMG_DST} ${IMG_TMP} && /bin/mv -fv ${IMG_TMP} ${IMG_DST} 

# Run virt-customize once (user customization), change to fit your needs, mdp is 'DarkSecr@et'
virt-customize ${VIRT_ARGS} -a ${IMG_DST} \
--run-command '/usr/sbin/useradd -m -g wheel -p G4tS0vlvly9Po admin' \
--upload 99_admin:/etc/sudoers.d/99_admin \
--run-command 'chown root:root /etc/sudoers.d/99_admin' \
--run-command 'mkdir -p /home/admin/.ssh' \
--run-command '/usr/sbin/usermod -p M8rFtLIr5t4vk root' \
--run-command 'echo "${STACK_SSH_KEY}" > /home/admin/.ssh/authorized_keys' \
--run-command 'chown -R admin:wheel /home/admin/.ssh' \
--run-command 'chmod 700 /home/admin/.ssh;chmod 600 /home/admin/.ssh/authorized_keys' \

# Customize the host name..
virt-customize ${VIRT_ARGS} -a ${IMG_DST} \
--run-command 'echo "sensu01" > /etc/hostname' \
--run-command 'echo "HOSTNAME=sensu01" >> /etc/sysconfig/network' \
--run-command 'echo "NOZEROCONF=yes" >> /etc/sysconfig/network' \
--run-command 'echo "NETWORKING=yes" >> /etc/sysconfig/network' \
--run-command 'echo "NETWORKING_IPV6=yes" >> /etc/sysconfig/network' \
--run-command 'echo "IPV6FORWARDING=yes" >> /etc/sysconfig/network' \
--run-command 'echo "PRETTY_HOSTNAME=sensu01" > /etc/machine-info' \
--run-command 'sed -i -e "s/localhost localhost.localdomain/sensu01 localhost localhost.localdomain/" /etc/hosts'

# software install and customization happens here.
virt-customize ${VIRT_ARGS} -a ${IMG_DST} \
--run-command "subscription-manager register --username=\"${SM_USER}\" --password=\"${SM_PASSWD}\"" \
--run-command "subscription-manager attach --pool=\"${SM_POOL_ID}\"" \
--run-command 'subscription-manager repos --disable=*' \
--run-command 'subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-7-server-extras-rpms --enable=rhel-7-server-optional-rpms --enable=rhel-7-server-debug-rpms --enable=rhel-7-server-openstack-7.0-rpms --enable=rhel-7-server-openstack-7.0-optools-rpms' \
--run-command 'yum -y install psutil python-ceilometerclient python-cinderclient python-glanceclient python-keystoneclient python-neutronclient python-novaclient six' \
--run-command 'sed -i -e "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config' \
--run-command 'yum -y update' \
--run-command 'yum -y install redis rabbitmq-server ruby-devel rubygems make gcc g++ screen' \
--run-command 'yum -y install python-psutil python-six python-paramiko python-httplib2' \
--run-command 'yum -y install puppet puppet-server nano bind-utils tcpdump perl' \
--run-command 'yum -y remove cloud-init' \
--run-command 'systemctl enable sshd' \
--run-command '/usr/sbin/grubby --update-kernel=ALL --args="console=tty0 console=ttyS0,115200n8"' \
--run-command 'yum clean all' \
--run-command 'echo subscription-manager unregister' \
--run-command 'echo subscription-manager clean'

# inject ansible rpm into the image.. Right now we obtain it from EPEL but this will change.
PKGS="\
http://dl.fedoraproject.org/pub/epel/7/x86_64/p/python-crypto-2.6.1-1.el7aos.x86_64.rpm \
http://dl.fedoraproject.org/pub/epel/7/x86_64/p/python-ecdsa-0.11-3.el7aos.noarch.rpm \
http://dl.fedoraproject.org/pub/epel/7/x86_64/p/python-httplib2-0.9.1-2.el7aos.noarch.rpm \
http://dl.fedoraproject.org/pub/epel/7/x86_64/p/python-keyczar-0.71c-2.el7.noarch.rpm \
http://dl.fedoraproject.org/pub/epel/7/x86_64/p/python-paramiko-1.15.2-1.el7aos.noarch.rpm \
http://dl.fedoraproject.org/pub/epel/7/x86_64/p/python-pyasn1-0.1.9-1.el7ost.noarch.rpm \
http://dl.fedoraproject.org/pub/epel/7/x86_64/s/sshpass-1.05-5.el7.x86_64.rpm
http://dl.fedoraproject.org/pub/epel/7/x86_64/a/ansible-2.0.1.0-2.el7.noarch.rpm \
http://dl.fedoraproject.org/pub/epel/7/x86_64/p/pkcs11-helper-1.11-3.el7.x86_64.rpm \
http://dl.fedoraproject.org/pub/epel/7/x86_64/p/python-pip-7.1.0-1.el7.noarch.rpm \
http://dl.fedoraproject.org/pub/epel/7/x86_64/k/keychain-2.7.1-1.el7.noarch.rpm \
http://rhos-release.virt.bos.redhat.com/repos/rhos-release/rhos-release-latest.noarch.rpm \
"
pkg_list=""
for mypkg in ${PKGS}
do
	PKG_URL="${mypkg}"
	PKG_RPM="$(basename ${PKG_URL})"
	if [ ! -d rpms ]; then
		mkdir rpms
	fi
	if [ ! -f rpms/${PKG_RPM} ]; then
		wget -c  ${PKG_URL} -O rpms/${PKG_RPM}
	fi
	virt-customize ${VIRT_ARGS} -a ${IMG_DST} \
	--upload rpms/${PKG_RPM}:/tmp/${PKG_RPM}
	pkg_list="${pkg_list} /tmp/${PKG_RPM}"
done

virt-customize ${VIRT_ARGS} -a ${IMG_DST} \
	--run-command "yum -y install ${pkg_list}"

if [ "x$wantvbox" = "x1" ]; then
	qemu-img convert -O vdi ${IMG_DST} ${VDI_DST}
fi
