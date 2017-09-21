# Sabayon Reload Scripts

Build Sabayon from scratch with Ansible and Docker for:

  * check periodically if all sabayon-distro and for-gentoo overlay
    works correctly

  * simplify process for create a custom Sabayon Distro with
    different USE flags

  * simplify process for manage local repository

NOTE: It's under development. Not completed.

It is based on Sabayon Dockerfile written by mudler and Sabayon Team.

## The Story

TBD

## Process steps

### 1. stage3-gentoo-systemd-amd64

From Gentoo Stage3 tarball is created a docker image after update portage, rebuild @world and
remove some unneeded packages.

Ansible tag for this image is *gentoo_stage3*.

### 2. stage3-sabayon-amd64

From stage3-gentoo-systemd-amd64 is installed equo and entropy.

Ansible tag for this image is *sabayon_stage3*.

## Images Tree

```

gentoo-stage3
     |
     |
     \--> sabayon-stage3 ------> sabayon-base  ----> sabayon-spinbase --> sabayon-builder
                          \
                           \
                            ---> sabayon-base-reload ---> sabayon-rebuilder
```

## Build Images

Under ansible directory, for build step 1:

```bash
  $# ansible-playbook --tag gentoo_stage3 build.yml
```

