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

From Gentoo Stage3 tarball is created a docker image with updated portage is rebuild @world and
removed some packages.

Ansible tag for this image is *gentoo_stage3*.

## Build Images

```bash
  $# ansible-playbook --tag gentoo_stage3 build.yml
```

