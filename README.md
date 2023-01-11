# auks

This module builds, installs and configures the [Aside Utility for Kerberos Support (AUKS)](https://github.com/cea-hpc/auks), which can be used to forward Kerberos authentications from the scheduler node of a Slurm cluster to the compute nodes. This way, it is possible to access Kerberos-protected resources like NFS4+KRB5 file shares.

## Table of Contents

1. [Description](#description)
1. [Setup – The basics of getting started with auks](#setup)
    * [What auks affects](#what-auks-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with auks](#beginning-with-auks)
1. [Usage – Configuration options and additional functionality](#usage)
1. [Limitations – OS compatibility, etc.](#limitations)
1. [Development – Guide for contributing to the module](#development)

## Description
The AUKS daemon solves the problem of users having to access to their Kerberos tickets on Slurm compute nodes, because their sessions on these nodes are created using Munge without a user password. This results in problems like the inability to access file shares that need authentication with Kerberos, e.g. NFS4+KRB5.

AUKS needs to be built from [sources](https://github.com/cea-hpc/auks) and installed from the RPMs. Other methods do not create the unit files for starting the services. Therefore, this module automates the whole build process by (i) obtaining the sources from GitHub, (ii) running the whole build pipeline, (iii) creating the RPMs from the binaries, (iv) installing said RPMs and (v) providing the configuration files. In step (iii), there is the option to remove the dependency on the Slurm RPMs for cases in which Slurm is built from source an known to be available on all nodes.

The module configures the AUKS login node from which the credentials are distribute as well as the compute nodes which receive the data. Please note that the module does not configure the following aspects:

* The firewall on the nodes. You must use a separate module for modifying firewall settings. A port rule for the port configured as `auks::primary_server::port` and `auks::secondary_server::port` is required.
* The registration of the Slurm SPANKS plugin. Use the module you use for installing Slurm to do this and to set the required arguments (cf. https://github.com/cea-hpc/auks).

## Setup

### What auks affects
Besides installing AUKS, the module will install development dependencies (C++ toolchain) that are required to build the service and the Slurm plugins from source.

AUKS services will be enabled and started depending on the role of the node. The role is determined by parsing the input for the configuration file, which requires specifying the primary and secondary AUKS server by DNS and principal name.

### Setup Requirements
This module requires Slurm to be installed on machines it affects. The module itself will not perform this installation, so you are free to choose any module you want to do that. We are using [treydock-slurm](https://forge.puppet.com/modules/treydock/slurm/).

As the only reason to install AUKS is distributing Kerberos tickets to compute nodes, you need to have a KDC like Active Directory set up correctly. The login node and the compute node must be members of the Kerberos realm.

### Beginning with auks

When using Hiera, installing AUKS is fairly trivial in that just the class needs to be included. Please note, however, that manual work is required for configuring the firewall and the Slurm SPANKS plugin.

## Usage
The auks resource can be fully configured via Hiera. Assuming a Slurm installation
based on `treydock-slurm`, the configuration could look like:

```puppet
# Configure slurmctld/slurmd via Hiera.
include slurm

# Configure AUKS via Hiera.
include auks

# Enable the SPANKS plugin:
slurm::spank { 'auks':
    ensure => present,
    arguments => [ 'default=enabled', 'spankstackcred=yes', 'minimum_uid=1024' ],
    manage_package => false
}
```

The default configuration provided via Hiera mostly follows the defaults from the sample configuration files of AUKS. However, you must configure at least the `primary_server` and the rules for the principals (admin rules for the `primary_server` and the optional `secondary_server` will be generated automatically, so you only need to cover the compute nodes and the users). An example configuration might look like:

```yaml
auks::primary_server:
  name: 'thrashcore.some-university.de'
  port: 14863
  principal: 'THRASHCORE$@SOME-UNIVERSITY.DE'

auks::rules:
  - principal: '^CADINTULNIC\$@SOME\-UNIVERSITY\.DE$'
    host: '*'
    role: 'admin'
  - principal: '^DEDRAGOSTE\$@SOME\-UNIVERSITY\.DE$'
    host: '*'
    role: 'admin'
  - principal: '^LEGENYES\$@SOME\-UNIVERSITY\.DE$'
    host: '*'
    role: 'admin'
  - principal: '^ZNAMENNYCHANT\$@SOME\-UNIVERSITY\.DE$'
    host: '*'
    role: 'admin'
  - principal: '^[[:alnum:]]+@SOME\-UNIVERSITY\.DE$'
    host: '*'
    role: 'user'
```

Please note that the implicit rules generated for `primary_server` and the optional `secondary_server` are automatically escaped for use in regular expressions. The explicitly specified rules, however, are copied verbatim into the configuration file, so you must escape and special characters in regular expressions that you want to match.

## Limitations

This module only works on RedHat-based distributions. See `metadata.json`.

## Development

Open a pull request on [GitHub](https://github.com/UniStuttgart-VISUS/visus-auks).
