# == Class: mongodb
#
class mongodb (
  $dbdir           = $mongodb::params::dbdir,
  $pidfilepath     = $mongodb::params::pidfilepath,
  $logdir          = $mongodb::params::logdir,
  $logrotatenumber = $mongodb::params::logrotatenumber,
  $ulimit_nofiles  = $mongodb::params::ulimit_nofiles,
  $run_as_user     = $mongodb::params::run_as_user,
  $run_as_group    = $mongodb::params::run_as_group,
  $old_servicename = $mongodb::params::old_servicename
) inherits mongodb::params {

    anchor{ 'mongodb::begin':
        before => Anchor['mongodb::install::begin'],
    }

    anchor { 'mongodb::end': }

    class { 'mongodb::logrotate':
        require => Anchor['mongodb::install::end'],
        before  => Anchor['mongodb::end'],
    }

    case $::osfamily {
        /(?i)(Debian|RedHat)/: {
            class { 'mongodb::install': }
        }
        default: {
            fail "Unsupported OS ${::operatingsystem} in 'mongodb' module"
        }
    }

    # stop and disable default mongod

    service {
        [$::mongodb::params::old_servicename]:
            ensure     => stopped,
            enable     => false,
            hasstatus  => true,
            hasrestart => true,
            subscribe  => Package['mongodb-10gen'],
            before     => Anchor['mongodb::end'],
    }

    # remove not wanted startup script, because it would kill all mongod
    # instances and not only the default mongod

    file {
        "/etc/init.d/${::mongodb::params::old_servicename}":
            ensure  => present,
            content => template("$module_name/replacement_mongod-init.conf.erb"),
            require => Service[$::mongodb::params::old_servicename],
            mode    => 0755,
            before  => Anchor['mongodb::end'],
    }

  mongodb::limits::conf {
    'mongod-soft':
      type  => soft,
      item  => nofile,
      value => $mongodb::params::ulimit_nofiles;
    'mongod-hard':
      type  => hard,
      item  => nofile,
      value => $mongodb::params::ulimit_nofiles;
  }

}

