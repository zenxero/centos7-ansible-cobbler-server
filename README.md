# Archival Purposes

# WARNING - This playbook is outdated and no longer works on modern RHEL-Like distros.

This an archive of an Ansible playbook that used to work circa 2017 or so. It only targets CentOS 7 and unfortunately the Cobbler project no longer seems to work. Updated versions of the Cobbler server package on CentOS 7 also remove a sub-command called `get-loaders` that installed the bootloaders required for the PXE boot process. An archive of those files can be found here:
https://github.com/hbokh/cobbler-loaders

Github issue for the `cobbler get-loaders` problem: https://github.com/cobbler/cobbler/issues/2660

# Deploy Cobbler Server

This repo contains an Ansible playbook that will automatically configure a CentOS 7 system to be a Cobbler PXE boot server for bare-metal or VM deployments.

## Table of Contents
  * [Requirements](#requirements)
  * [Usage](#usage)
  * [Adding systems to Cobbler](#addingsystems)
  * [Profiles and disk layouts](#profiles)
  * [Repos](#repos)

<a name="requirements"></a>
## Requirements

  * [Ansible Control System Requirements](https://docs.ansible.com/ansible/latest/intro_installation.html#control-machine-requirements)
  * A system with the `ansible` and `git` packages installed.
  * The ability to SSH to the target system as root with an SSH key.
  * The target system that will be the Cobbler server needs to be running the CentOS 7 Linux distribution.
  * The target CentOS 7 system should have a valid FQDN (Fully Qualified Domain Name) on your local network.

<a name="usage"></a>
## Usage

This is a standalone playbook, meaning that it includes its own `ansible.cfg` file and does not need a system-level config file.

To use this playbook:

1. On your "control" system with ansible and git installed, clone this git repo.

2. In the [hosts](hosts) file, add the hostname of the system that you want to be your Cobbler server.

3. In the [deploy-cobbler-server](deploy-cobbler-server.yml) file, configure the following variables:
  * The `centos_7_minimal_iso` variable. This should be the location of a CentOS 7 minimal iso file to download. It uses the Princeton CentOS mirror by default.
  * The `ubuntu_16_iso` variable. This should be the location of a Ubuntu 16.04 server iso file to download. It uses the releases.ubuntu.com website by default.
  * The `default_password_crypted` variable. Use this to set the default root password on systems built from Cobbler. Use either `mkpasswd` or `openssl passwd -1` to create a password.
  * The `root_ssh_public_key` variable. Use this to set a public ssh key for the root user on systems built from Cobbler.
  * The `ntp_server` variable. This uses `time.google.com` by default.
  * You can also configure build report emails and LDAP authentication, but these are turned off by default.

4. Run the playbook with the following command:

```
ansible-playbook deploy-cobbler-server.yml
```

In a few minutes, you should have a working Cobbler server.

After the playbook is finished, you can access the web interface of your Cobbler server by navigating to:

  * `https://your-hostname.example.com/cobbler_web`

This installation uses a self-signed SSL cert by default, so your browser will warn you that it can't validate the cert and that it may not be secure. Just continue through to the login page.

To log in, use the following credentials:
  * **Username:** cobbler
  * **Password:** cobbler

**NOTE:** To change the password for the Cobbler user, run the following command:

```
htdigest /etc/cobbler/users.digest "Cobbler" cobbler
```

<a name="addingsystems"></a>
## Adding systems to Cobbler

You can use the web interface to add systems that you want to PXE boot.

However, if you prefer the command-line, you can also add systems that way.

To add a system, use the following command:

```
cobbler system add --name=server.example.com --netboot=yes --status=testing --profile=centos-7-atomic-server --interface=eth0 --mac=00:11:22:33:44:55
```

**NOTE:** You will need to replace the information given to the `--name=` and `--mac=` flags for the system that you are adding.

For more information on Cobbler command-line syntax, see the [Cobbler Manual](https://cobbler.github.io/manuals/2.8.0/).

## Distros

This playbook imports two distros into Cobbler:

  1. CentOS 7.4 x86_64
  2. Ubuntu 16.04.4 x86_64

<a name="profiles"></a>
## Profiles and disk layouts

**NOTE:** All disk partitions and volumes use the XFS filesystem. A 1 MB `biosboot` partition is also created to make the disk GPT compatible. See [this Arch Linux wiki page for more information on GPT](https://wiki.archlinux.org/index.php/GRUB#GUID_Partition_Table_.28GPT.29_specific_instructions).

You can alter the disk layouts by editing the following files:

  * [centos_7_atomic_diskpart](roles/deploy-cobbler-server/files/snippets/centos_7_atomic_diskpart)
  * [centos_7_partitioned_diskpart](roles/deploy-cobbler-server/files/snippets/centos_7_partitioned_diskpart)
  * [ubuntu_16_atomic_server.seed](roles/deploy-cobbler-server/templates/kickstarts/ubuntu_16_atomic_server.seed.j2)
  * [ubuntu_16_partitioned_server.seed](roles/deploy-cobbler-server/templates/kickstarts/ubuntu_16_partitioned_server.seed.j2)

This playbook creates four profiles based on the two distros listed above.

1. _centos-7-atomic-server_ - This profile installs a CentOS 7 server with an "atomic" disk layout. This means that the disk layout is one large logical volume, plus the `/boot` partition and 4 GB of SWAP space.

```
[root@myserver-test ~]# df -hlPT | grep -v tmpfs
Filesystem                          Type      Size  Used Avail Use% Mounted on
/dev/mapper/myserver_test_sys-root xfs        92G  1.7G   91G   2% /
/dev/sda2                           xfs       4.0G  166M  3.9G   5% /boot

[root@myserver-test ~]# lsblk
NAME                        MAJ:MIN  RM  SIZE RO TYPE MOUNTPOINT
sda                         8:0      0   100G  0 disk 
├─sda1                      8:1      0     1M  0 part 
├─sda2                      8:2      0     4G  0 part /boot
└─sda3                      8:3      0    96G  0 part 
  ├─myserver_test_sys-root 253:0    0    92G  0 lvm  /
  └─myserver_test_sys-swap 253:1    0     4G  0 lvm  [SWAP]
```

2. _centos-7-partitioned-server_ - This profile installs a CentOS 7 server with a partitioned disk layout using LVM. The volume scheme is as follows:
  * 4 GB /boot
  * 32 GB /
  * 4 GB /var
  * 4 GB /tmp
  * 4 GB SWAP
  * Fills remaining disk space into the /srv volume

```
[root@myserver-test ~]# df -hlPT | grep -v tmpfs
Filesystem                          Type      Size  Used Avail Use% Mounted on
/dev/mapper/myserver_test_sys-root xfs        32G  1.6G   31G   5% /
/dev/mapper/myserver_test_sys-var  xfs       4.0G  109M  3.9G   3% /var
/dev/mapper/myserver_test_sys-srv  xfs        52G   33M   52G   1% /srv
/dev/mapper/myserver_test_sys-tmp  xfs       4.0G   33M  4.0G   1% /tmp
/dev/sda2                           xfs       4.0G  166M  3.9G   5% /boot

[root@myserver-test ~]# lsblk
NAME                        MAJ:MIN  RM  SIZE RO TYPE MOUNTPOINT
sda                         8:0      0   100G  0 disk 
├─sda1                      8:1      0     1M  0 part 
├─sda2                      8:2      0     4G  0 part /boot
└─sda3                      8:3      0    96G  0 part 
  ├─myserver_test_sys-root 253:0    0    32G  0 lvm  /
  ├─myserver_test_sys-swap 253:1    0     4G  0 lvm  [SWAP]
  ├─myserver_test_sys-srv  253:2    0    52G  0 lvm  /srv
  ├─myserver_test_sys-tmp  253:3    0     4G  0 lvm  /tmp
  └─myserver_test_sys-var  253:4    0     4G  0 lvm  /var 
```

3. _ubuntu-16-atomic-server_ - Same as the CentOS 7 atomic server profile, but with Ubuntu 16.04.

4. _ubuntu-16-partitioned-server_ - Same as the CentOS 7 partitioned server profile, but with Ubuntu 16.04.

<a name="repos"></a>
## Repos

This playbook creates several package repo mirrors that the systems can use.

For CentOS 7, the following package repos are created as pointers to http://mirror.centos.org:
  * centos-7-base
  * centos-7-updates
  * centos-7-extras
  * centos-7-fasttrack
  * centos-7-epel - Points to http://download.fedoraproject.org/pub/epel/7/x86_64

For Ubuntu 16.04, the default package repos from http://archive.ubuntu.com/ubuntu are used.

**NOTE:** None of the package repos are set to mirror locally. They are just pointers to the external repositories.
