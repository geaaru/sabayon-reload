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

For now only for amd64 platform.

### 1. stage3-gentoo-systemd-amd64

From Gentoo Stage3 tarball is created a docker image after update portage, rebuild @world and
remove some unneeded packages.

Ansible tag for this image is *gentoo_stage3*.

### 2. stage3-sabayon-amd64

From stage3-gentoo-systemd-amd64 is installed equo and entropy.

Ansible tag for this image is *sabayon_stage3*.

### 3. sabayon-base-amd64

From stage3-sabayon-amd64 is configure sabayon repository and sync with last packages version.


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

For build step 2:

```bash
  $# ansible-playbook --tag sabayon_stage3 build.yml
```

For build all:

```bash
  $# ansible-playbook build.yml
```

### Customize Build Process

Current ansible configuration permit build process on localhost but it is possible configure Ansible to build images to a remote machine.
See Ansible documentation for details.

In particular, under localhost host variable file it is possible customize this options.

| Option   |  Default | Description |
|----------|----------|-------------|
| builder_rootdir  | ..  | Path of the sabayon-reload project tree.  |
| docker_user  | geaaru  | Name of the user used for create docker images  |
| gentoo_dist_server  | http://distfiles.gentoo.org/  | URL where retrieve portage tarball and gentoo stage3 file.  |
| gentoo_skip_sync | 1 | Execute portage sync before build process (1) or not (0). |
