# @summary Builds the RPM files to install AUKS.
#
# @param src_dir The directory where the source has been placed into. The
#                resulting RPM files will be placed in this directory, too.
# @param patch_slurm_dependency If true, the build process will patch the spec
#                               file created by the configure step to exclude
#                               the Slurm runtime and build dependencies in the
#                               RPM. This is required if Slurm has been built
#                               from source instead of installing it from a
#                               package repository.
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
    ~> exec { 'auksbuild-patchspec':
        path => "${src_dir}:/usr/bin:/bin:/usr/sbin:/sbin",
        command => $patch_cmd,
        cwd => $src_dir,
        refreshonly => true
    }

    # Build RPMs.
    ~> exec { 'auksbuild-makerpm':
        path => "${src_dir}:/usr/bin:/bin:/usr/sbin:/sbin",
        # Note: this does not work w/o the cd, bc otherwise, the path to
        # .rpmbuild is broken.
        command => "cd ${src_dir} && make rpm",
        cwd => $src_dir,
        refreshonly => true
    }
}
