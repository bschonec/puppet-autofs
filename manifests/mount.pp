# Defined Type Docmentation

define autofs::mount (
  $mount,
  $mapfile,
  $mapcontents,
  $options,
  $order,
) {

  concat { '/etc/auto.master':
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Service[ 'autofs' ],
  }

  concat::fragment { 'autofs::fragment preamble /etc/auto.master':
    ensure  => present,
    target  => '/etc/auto.master',
    content => "${mount} /etc/${mapfile} ${options}",
    order   => $order,
  }

  file { $mount:
    ensure => directory,
  }

  file { "/etc/${mapfile}":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('etc/auto.map.erb'),
    require => File[ $mount ],
    notify  => Service[ 'autofs' ],
  }

}