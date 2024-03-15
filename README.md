# Bay of Rum policies

A set for FreeBSD servers and workstations and Raspberry Pis.

Bootstrapping:

```console
# sysrc hostname=my_new_hostname.bayofrum.net
# tzsetup Europe/London
# mkdir -p /usr/local/etc/sudoers.d
# echo "$(whoami) ALL=(ALL:ALL) NOPASSWD: ALL" > /usr/local/etc/sudoers.d/staff_nopasswd
# env ASSUME_ALWAYS_YES=yes pkg install sudo py39-ansible git
# install -m 600 /dev/null /etc/periodic.conf
# cat > /etc/periodic.conf <<EOF
> daily_ansible_pull_github_enable=yes
> daily_ansible_pull_github_repo=crees/bayofrum-ansible
> daily_ansible_pull_playbook=bayofrum.yml
> EOF
# . /etc/periodic.conf
# ansible-pull -vU https://github.com/$daily_ansible_pull_github_repo -i inventory bayofrum.yml
# pkg set -v 1 pam_mkhomedir sssd-smb
```

