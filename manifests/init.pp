# @summary Installs and configures AUKS.
#
# @param dependencies A list of packages that need to be installed to build
#                     the AUKS RPMs.
# @param repository_url The URL of the Git repository to get the sources from.
# @param repository_revision The revision to retrieve from Git.
# @param primary_server The FQDN of the primary AUKS server.
# @param patch_slurm_dependency Patch out the dependency on Slurm packages from
#                               the RPM. This is required if Slurm has been
#                               built from source on the target machine. This
#                               parameter defaults to false.
# @param source_directory The directory where the sources of AUKS should be
#                         stored. This parameter defaults to '/usr/local/src'.
#
# @author Christoph Müller
class auks(
        Array[String] $dependencies,
        String $repository_url,
        String $repository_revision,
        Hash $primary_server,
        Hash $common,
        Hash $api,
        Hash $auksd,
        Hash $renewer,
        Array[Hash] $rules,
        Optional[Hash] $secondary_server = undef,
        Boolean $patch_slurm_dependency = false,
        String $source_directory = '/usr/local/src',
        String $config_file = '/etc/auks/auks.conf'
        ) {

    # Install dependencies we need to build AUKS.
    ensure_packages($dependencies)

    # Checkout the sources.ll
    $src_dir = "${source_directory}/auks"
    vcsrepo { $src_dir:
        ensure => present,
        provider => git,
        source => $repository_url,
        revision => $repository_revision
    }

#    # Determine where we actually get AUKS from.
#    $source_url = if $source_override {
#        $source_override
#    } else {
#        "https://github.com/cea-hpc/auks/archive/refs/tags/v${version}.tar.gz"
#    }

    # Build the RPMs.
    ~> auks::build { 'auks-build':
        src_dir => $src_dir,
        patch_slurm_dependency => $patch_slurm_dependency
    }

    # Apply the configuration.
    file { $config_file:
        ensure => file,
        owner => 'root',
        group => 'root',
        mode => '644',
        content => epp('auks/auks.conf.epp', {
            primary_server => $primary_server,
            secondary_server => $secondary_server,
            common => $common,
            api => $api,
            auksd => $auksd,
            renewer => $renewer
        })
    }

    # Configure the access rules.
    $primary_rule = {
        principal => "^${regsubst($primary_server['principal'], '\.', '\.', 'G')}$",
        host => '*',
        role => 'admin'
    }
    $builtin_rules = if $secondary_server {
        $secondary_rule = {
            principal => regsubst($secondary_server['principal'], '\.', '\.', 'G'),
            host => '*',
            role => 'admin'
        }
        [ $primary_rule, $secondary_rule ]
    } else {
        [ $primary_rule ]
    }

    file { $auksd['ACLFile']:
        ensure => file,
        owner => 'root',
        group => 'root',
        mode => '644',
        content => epp('auks/auks.acl.epp', {
            builtin_rules => $builtin_rules,
            rules => $rules
        })
    }
}
