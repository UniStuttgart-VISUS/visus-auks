# auks

This module builds, installs and configures the [Aside Utility for Kerberos Support (AUKS)](https://github.com/cea-hpc/auks), which can be used to forward Kerberos authentications from the scheduler node of a Slurm cluster to the compute nodes. This way, it is possible to access Kerberos-protected resources like NFS4+KRB5 file shares.

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with auks](#setup)
    * [What auks affects](#what-auks-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with auks](#beginning-with-auks)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description
The AUKS daemon solves the problem of users having to access to their Kerberos tickets on Slurm compute nodes, because their sessions on these nodes are created using Munge without a user password. This results in problems like the inability to access file shares that need authentication with Kerberos, e.g. NFS4+KRB5.

AUKS needs to be built from [sources](https://github.com/cea-hpc/auks) and installed from the RPMs. Other methods do not create the unit files for starting the services. Therefore, this module automates the whole build process by (i) obtaining the sources from GitHub, (ii) running the whole build pipeline, (iii) creating the RPMs from the binaries, (iv) installing said RPMs and (v) providing the configuration files. In step (iii), there is the option to remove the dependency on the Slurm RPMs for cases in which Slurm is built from source an known to be available on all nodes.

The module configures the AUKS login node from which the credentials are distribute as well as the compute nodes
which receive the data. Please note that the module does not configure the following aspects:

* The firewall on the nodes. You must use a separate module for modifying firewall settings. A port rule for the
port configured as `auks::primary_server::port` and `auks::secondary_server::port` is required.
* The registration of the Slurm SPANKS plugin. Use the module you use for installing Slurm to do this. If you are
using `treydock-slurm`, this can by accomplished by (cf. https://github.com/hautreux/auks/blob/master/HOWTO):

```puppet
    slurm::spank { 'auks':
        ensure => present,
        arguments => [ 'default=enabled', 'spankstackcred=yes', 'minimum_uid=1024' ],
        manage_package => false
    }
```

## Setup

### What auks affects **OPTIONAL**

If it's obvious what your module touches, you can skip this section. For
example, folks can probably figure out that your mysql_instance module affects
their MySQL instances.

If there's more that they should know about, though, this is the place to
mention:

* Files, packages, services, or operations that the module will alter, impact,
  or execute.
* Dependencies that your module automatically installs.
* Warnings or other important notices.

### Setup Requirements **OPTIONAL**

If your module requires anything extra before setting up (pluginsync enabled,
another module, etc.), mention it here.

If your most recent release breaks compatibility or requires particular steps
for upgrading, you might want to include an additional "Upgrading" section here.

### Beginning with auks

The very basic steps needed for a user to get the module up and running. This
can include setup steps, if necessary, or it can be an example of the most basic
use of the module.

## Usage

Include usage examples for common use cases in the **Usage** section. Show your
users how to use your module to solve problems, and be sure to include code
examples. Include three to five examples of the most important or common tasks a
user can accomplish with your module. Show users how to accomplish more complex
tasks that involve different types, classes, and functions working in tandem.

## Reference

This section is deprecated. Instead, add reference information to your code as
Puppet Strings comments, and then use Strings to generate a REFERENCE.md in your
module. For details on how to add code comments and generate documentation with
Strings, see the [Puppet Strings documentation][2] and [style guide][3].

If you aren't ready to use Strings yet, manually create a REFERENCE.md in the
root of your module directory and list out each of your module's classes,
defined types, facts, functions, Puppet tasks, task plans, and resource types
and providers, along with the parameters for each.

For each element (class, defined type, function, and so on), list:

* The data type, if applicable.
* A description of what the element does.
* Valid values, if the data type doesn't make it obvious.
* Default value, if any.

For example:

```
### `pet::cat`

#### Parameters

##### `meow`

Enables vocalization in your cat. Valid options: 'string'.

Default: 'medium-loud'.
```

## Limitations

In the Limitations section, list any incompatibilities, known issues, or other
warnings.

## Development

In the Development section, tell other users the ground rules for contributing
to your project and how they should submit their work.

## Release Notes/Contributors/Etc. **Optional**

If you aren't using changelog, put your release notes here (though you should
consider using changelog). You can also add any additional sections you feel are
necessary or important to include here. Please use the `##` header.

[1]: https://puppet.com/docs/pdk/latest/pdk_generating_modules.html
[2]: https://puppet.com/docs/puppet/latest/puppet_strings.html
[3]: https://puppet.com/docs/puppet/latest/puppet_strings_style.html


