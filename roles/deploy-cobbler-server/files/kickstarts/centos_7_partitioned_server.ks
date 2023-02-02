install
auth --useshadow --enablemd5
url --url=$tree
lang en_US.UTF-8
keyboard us
firstboot --disable
$SNIPPET('network_config')
## xconfig --startxonboot --defaultdesktop gnome
rootpw --iscrypted $default_password_crypted
## The default password is "password"
## sshpw --username=root $6$3B9OMC8Nvc0hnflS$IY3rh0nNZ/6AiS0z0Tun4DhvSmvt56wofAs35PrxGhLnYXC6wLv0e18RCnLb7C6/O4XEh1FximkOpqt7auEqk1 --iscrypted
selinux --permissive
firewall --disabled

repo --name=centos-7-base --baseurl=http://mirror.centos.org/centos-7/7/os/x86_64/
repo --name=centos-7-updates --baseurl=http://mirror.centos.org/centos-7/7/updates/x86_64/
repo --name=centos-7-fasttrack --baseurl=http://mirror.centos.org/centos-7/7/fasttrack/x86_64/
repo --name=centos-7-extras --baseurl=http://mirror.centos.org/centos-7/7/extras/x86_64/
repo --name=centos-7-epel --baseurl=http://download.fedoraproject.org/pub/epel/7/x86_64

services --enabled=NetworkManager,sshd
eula --agreed
reboot
timezone --utc America/Chicago

#set $disk = $getVar('$disk', 'sda')
bootloader --location=mbr --driveorder=$disk --append="crashkernel=auto rhgb quiet"
$SNIPPET('centos_7_partitioned_diskpart')

## START PRE-KICKSTART SECTION
%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
## Enable installation monitoring
$SNIPPET('pre_anamon')
%end
## END PRE-KICKSTART SECTION

## START PACKAGES SECTION
%packages
@core
@base
@fonts
@hardware-monitoring
@java-platform
@development
nfs-utils
yum-plugin-priorities
-initial-setup
%end
## END PACKAGES SECTION

## START POST-KICKSTART SECTION
%post
$SNIPPET('log_ks_post')
## Start yum configuration
$yum_config_stanza
## Stop yum configuration
$SNIPPET('post_install_kernel_options')
$SNIPPET('post_install_network_config')
$SNIPPET('add_root_ssh_key')
$SNIPPET('koan_environment')
$SNIPPET('centos_post_install_bootstrap')
## Enable post-install boot notification
$SNIPPET('post_anamon')
$SNIPPET('kickstart_done')
%end
## END POST-KICKSTART SECTION
