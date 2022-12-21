# @api private
#
# @author Christoph Müller
define auks::build(
        String $src_dir,
        Boolean $patch_slurm_dependency
        ) {
    $patch_cmd = if $patch_slurm_dependency {
        "sed -i -E 's/^\s*(BuildRequires|Requires)\s*:\s*slurm.+/# \0/g' ${src_dir}/auks.spec"
    } else {
        'echo "Nothing to see here ..."'
    }

    # Run autoconfig.
    exec { 'auksbuild-autoconfigure':
        path => "${src_dir}:/usr/bin:/bin:/usr/sbin:/sbin",
        command => 'autoreconf -fvi',
        cwd => $src_dir,
        creates => "${src_dir}/configure",
        #refreshonly => true,
    }

    # Configure.
    ~> exec { 'auksbuild-configure':
        path => "${src_dir}:/usr/bin:/bin:/usr/sbin:/sbin",
        command => "configure",
        cwd => $src_dir,
        creates => "${src_dir}/config.h",
        refreshonly => true,
    }

    # Patch away slurm dependencies if requested.
    ~> exec { 'auskbuild-patchspec':
        path => "${src_dir}:/usr/bin:/bin:/usr/sbin:/sbin",
        command => $patch_cmd,
        cwd => $src_dir,
        refreshonly => true
    }

    # Build RPMs.
    ~> exec { 'auskbuild-makerpm':
        path => "${src_dir}:/usr/bin:/bin:/usr/sbin:/sbin",
        # Note: this does not work w/o the cd, bc otherwise, the path to
        # .rpmbuild is broken.
        command => "cd ${src_dir} && make rpm",
        cwd => $src_dir,
        refreshonly => true
    }

  # ~> exec { 'ldconfig-slurm':
  #   path        => '/usr/bin:/bin:/usr/sbin:/sbin',
  #   command     => 'ldconfig',
  #   refreshonly => true,
  # }

  # if $slurm::slurmd {
  #   systemd::unit_file { 'slurmd.service':ll
  #     source  => "file:///${src_dir}/etc/slurmd.service",
  #     require => Exec['install-slurm'],
  #     notify  => Service['slurmd'],
  #   }
  # }
  # if $slurm::slurmctld {
  #   systemd::unit_file { 'slurmctld.service':
  #     source  => "file:///${src_dir}/etc/slurmctld.service",
  #     require => Exec['install-slurm'],
  #     notify  => Service['slurmctld'],
  #   }
  # }
  # if $slurm::slurmdbd {
  #   systemd::unit_file { 'slurmdbd.service':
  #     source  => "file:///${src_dir}/etc/slurmdbd.service",
  #     require => Exec['install-slurm'],
  #     notify  => Service['slurmdbd'],
  #   }
  # }
}
