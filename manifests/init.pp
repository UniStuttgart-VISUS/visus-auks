# @summary Installs and configures AUKS.
#
# @param dependencies A list of packages that need to be installed to build
#                     the AUKS RPMs.
# @param repository_url The URL of the Git repository to get the sources from.
# @param repository_revision The revision to retrieve from Git.
# @param primary_server The configuration of the primary AUKS server. The
#                       name, port and principal properties need to be provided
#                       for this server.
# @param common The attributes to be configured in the common section of the
#               auks.conf configuration file.
# @param api The attributes to be configured in the api section of the
#            auks.conf configuration file.
# @param auksd The attributes to be configured in the auksd section of the
#              auks.conf configuration file.
# @param renewer The attributes to be configured in the renewer section of the
#                auks.conf configuration file.
# @param rules The user-defined access rules. Each of the rules must specify
#              the principal, the host and the role.
# @param secondary_server The configuration of an optional secondary AUKS
#                         server. If specified, the same properties as for
#                         the primary server must be specified.
# @param patch_slurm_dependency Patch out the dependency on Slurm packages from
#                               the RPM. This is required if Slurm has been
#                               built from source on the target machine. This
#                               parameter defaults to false.
# @param source_directory The directory where the sources of AUKS should be
#                         stored. This parameter defaults to '/usr/local/src'.
# @param config_file The path to the AUKS configuration file. This parameter
#                    defaults to '/etc/auks/auks.conf'.
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

    # Extract the host name from the principal name and the configured host name
    # and use them to determine whether the node we are running on is an AUKS
    # server node.
    $primary_server_host = regsubst($primary_server['principal'], '(.+/)?([^@\$]+)$?@.*', '\\2', 'G')
    $secondary_server_host = if ($secondary_server) {
        regsubst($secondary_server['principal'], '(.+/)?([^@\$]+)$?@.*', '\\2', 'G')
    } else {
        ''
    }
    #notify { "Auks hosts from principal name are \"${primary_server_host}\" and \"${secondary_server_host}\".":}
    $primary_server_name = $primary_server['name']
    $secondary_server_name = if ($secondary_server) {
        $secondary_server['name']
    } else {
        ''
    }
    #notify { "Auks host names are \"${primary_server_name}\" and \"${secondary_server_name}\".":}

    $is_server = ($primary_server_name == $trusted['hostname'])
        or ($secondary_server_name == $trusted['hostname'])
        or ($primary_server_name == $trusted['certname'])
        or ($secondary_server_name == $trusted['certname'])
        or ($primary_server_host == $trusted['hostname'])
        or ($secondary_server_host == $trusted['hostname'])
        or ($primary_server_host == $trusted['certname'])
        or ($secondary_server_host == $trusted['certname'])

    # auksd and auksdrenewer are not started on client nodes, so remember this.
    $server_state = if ($is_server) {
        'running'
    } else {
        'stopped'
    }

    # In case we do not have Slurm from a repo, make sure that RPM does not
    # perform the dependency check when installing.
    $slurm_opts = if $patch_slurm_dependency {
        [ '--nodeps' ]
    } else {
        []
    }

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

    # Build the RPMs.
    ~> auks::build { 'auks-build':
        src_dir => $src_dir,
        patch_slurm_dependency => $patch_slurm_dependency
    }

    # Install the RPMs (I can't believe that actually worked ...).
    ~> package { 'auks':
        ensure => present,
        provider => rpm,
        source => "${src_dir}/auks-[0-9].[0-9].[0-9]*86_64.rpm"
    }
    ~> package { 'auks-slurm':
        ensure => present,
        provider => rpm,
        source => "${src_dir}/auks-slurm*.rpm",
        install_options => $slurm_opts
    }

    # Enable and start the services.
    ~> service { 'auksd':
        ensure => $server_state,
        enable => $is_server
    }

    ~> service { 'auksdrenewer':
        ensure => $server_state,
        enable => $is_server
    }

    ~> service { 'aukspriv':
        ensure => running,
        enable => true
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
        }),
        notify => [ Service['auksd'], Service['auksdrenewer'], Service['aukspriv'] ]
    }

    # Configure the built-in access rules, which make the AUKS servers
    # automatically admin. The client nodes must be specified by the user
    # in the configuration file.
    $primary_rule = {
        # Hack from https://tickets.puppetlabs.com/browse/PUP-9554
        principal => "^${String(Regexp($primary_server['principal'], true))}$",
        host => '*',
        role => 'admin'
    }
    $builtin_rules = if $secondary_server {
        $secondary_rule = {
            principal => "^${String(Regexp($secondary_server['principal'], true))}$",
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
        }),
        notify => Service['auksd']
    }
}
