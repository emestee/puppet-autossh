# Define an autossh daemon instance by creating an init.d script that launches this configuration. 
# Parameters:
# - Local $user for the daemon and SSH client processes, default = root
# - ssh $remote_host to connect to, mandatory
# - ssh $remote_user to connect as, defaults to $user
# - ssh $remote_port to connect to, defaults to 22
# - ssh $local_forwards - single entry or array in SSH -L format
# - ssh $remote_forwards - single entry or array in SSH -R format
# - ssh $dynamic_forwards - single entry or array in SSH -D format
# - autossh $monitor_port (-M parameter value), defaults to disabled, see autossh(1), this feature is not recommended for use
# - autossh $gatetime, defaults to disabled, see autossh(1)
# - autossh $first_poll, defaults to disabled, see autossh(1)
# - autossh $poll, defaults to disabled, see autossh(1)
# - autossh $maxstart, defaults to disabled, see autossh(1)
# - autossh $maxlifetime, defaults to disabled, see autossh(1)
# - autossh $autossh_logfile, defaults to disabled
# - autossh $autossh_loglevel, 0-7, defaults to disabled
define autossh::tunnel (
  $ensure       = 'present',
  $user = 'root',
  $remote_host,
  $remote_port  = '22',
  $remote_user  = 'absent',
  $local_forwards = 'absent',
  $remote_forwards = 'absent',
  $dynamic_forwards = 'absent',
  $monitor_port = 'absent',
  $gatetime     = 'absent',
  $first_poll   = 'absent',
  $poll         = 'absent',
  $maxstart     = 'absent',
  $maxlifetime  = 'absent',
  $autossh_logfile      = 'absent',
  $autossh_loglevel	= 'absent',
) {
  include autossh

  File { 
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  if ($local_forwards == 'absent' and $remote_forwards == 'absent' and $dynamic_forwards == 'absent') {
	fail('At least one type of forwarding ($local_forwards, $remote_forwards, or $dynamic_forwards) must be specified for meaningful tunneling')
  }

  $ssh_remote_port = "-p ${remote_port}"
  
  $real_remote_user = $remote_user ? {
      'absent' => $user,
      default => $remote_user,
  } 

  # According to the autossh documentation, using OpenSSH ServerAlive 
  # options is better than using a monitor port, so we do that by default.
  if ($monitor_port == 'absent') {
    $real_monitor_port = 0
    $ssh_extra_options = "-o ServerAliveInterval=30 -o ServerAliveCountMax=3"
  }
  else {
    $real_monitor_port = $monitor_port
    $ssh_extra_options = ''
  }

  if ($ensure == 'present') {

    $template = $::osfamily ? { 
      #'RedHat' => 'autossh/autossh-tunnel-redhat.erb',
      default => 'autossh/autossh-tunnel.erb'
    }

    file { "/etc/init.d/autossh-tunnel-${name}":
      ensure  => file,
      mode    => '0755',
      require => Class['autossh::package'],
      content => template($template),
      notify => Service["autossh-tunnel-${name}"],
    }
    service { "autossh-tunnel-${name}":
      ensure     => 'running',
      hasrestart => 'true',
      hasstatus  => 'true',
      require    => File["/etc/init.d/autossh-tunnel-${name}"],
    }
  }
  else {
    exec { "autossh-tunnel-${name}_stop":
      command => "/etc/init.d/autossh-tunnel-${name} stop",
      path => "/bin:/sbin:/usr/sbin:/usr/bin",
      onlyif => "test -x /etc/init.d/autossh-tunnel-${name} && test -e /var/run/autossh-tunnel-${name}.pid",
    } 
    file { "/etc/init.d/autossh-tunnel-${name}":
      ensure => absent,
      require => Exec["autossh-tunnel-${name}_stop"],
    }
  }
}
