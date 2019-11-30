#!/bin/bash

_slurm_dev_nfs_server=v.radia.run

slurm_dev_main() {
    if ! grep -i fedora  /etc/redhat-release >& /dev/null; then
        if [[ $(uname) == Darwin ]]; then
            install_err 'You need to run:

radia_run vagrant-dev fedora
vssh
radia_run slurm-dev
'
        fi
        install_err 'only works on Fedora Linux'
    fi
    if (( $EUID == 0 )); then
        install_err 'run as vagrant, not root'
    fi
    install_yum update
    slurm_dev_nfs
    # this will cause a reboot so do after NFS (which will modify fstab)
    install_repo_eval redhat-docker
    install_yum slurm-slurmd slurm-slurmctld
    dd if=/dev/urandom bs=1 count=1024 | install -m 400 -o munge -g munge /dev/stdin /etc/munge/munge.key
    local f
    for f in munge slurmctld slurmd; do
        systemctl start "$f"
        systemctl enable "$f"
    done

}

slurm_def_nfs() {
    install_yum nfs-utils
    if ! showmount -e "$_slurm_dev_nfs_server" >&/dev/null; then
        install_error '
on $_slurm_dev_nfs_server you need to:

dnf install -y nfs-utils
cat << EOF > /etc/exports.d/home_vagrant.exports
/home/vagrant 10.10.10.0/24(rw,root_squash,no_subtree_check,async,secure)
EOF
systemctl enable nfs-server
systemctl restart nfs-server

'
    fi
    # do this first, because we want to mount /etc/fstab on reboot
    echo "$_slurm_dev_nfs_server:/home/vagrant /home/vagrant nfs defaults,vers=4.1,soft,noacl,_netdev 0 0" \
         | sudo tee -a /etc/fstab > /dev/null
}

slurm_dev_no_nfs() {
    install_repo_eval code common
    # rerun source, because common installs pyenv
    install_source_bashrc
    mkdir -p ~/src/radiasoft
    cd ~/src/radiasoft
    local p
    for p in pykern sirepo; do
        if [[ -d $p ]]; then
            cd "$p"
            git pull
        else
            gcl "$p"
            cd "$p"
        fi
        for v in py3; do
            pyenv global "$v"
            pip uninstall -y "$p" >& /dev/null || true
            if [[ -r requirements.txt ]]; then
                pip install -r requirements.txt >& /dev/null
            fi
            pip install -e .
        done
        # ends up with "py3" default
        cd ..
    done
    # this box should not need py2
}