# Puppet autossh module

[Autossh](http://www.harding.motd.ca/autossh/) is a ssh client monitor that
creates persistent SSH tunnels. This module configures autossh, and thus
enables you to define a SSH tunnel with puppet.

**Please be careful when dealing with SSH. Mistakes can potentially leave your
servers exposed. Always verify that this module did what you *think* it should
have.**.

This module is a backward-incompatible fork of [jfryman/autossh](http://github.com/jfryman/autossh)
that provides additional features:

* Supports every type of forward (local to remote, remote to local, and dynamic SOCKS)
* Supports multiple forwards in the same configuration
* Supports autossh logging
* Works on Debian and Redhat systems (help with init.d scripts on other OSes welcome!)

## Compatibility

On RHEL, autossh is absent from the default yum repositories, and you may want to add rpmforge ones, 
as this module will attempt to install autossh and fail if it isn't available.

This module is known to work under puppet 3.x, and it is likely it will work
under earlier 2.7+ versions.

## Usage

This module creates a script in `/etc/init.d/autossh-tunnel-<name>` that starts
and stops the tunnel. It is intended for use on the side of the tunnel that is *initiating* the 
connection.

In order for the configured tunnel to work, you need to take additional steps that are
beyond the scope of this module:

* Create the local tunnel user and a SSH keypair
* Create the remote tunnel user and distribute the public key of the tunnel to it
* Ensure that the remote SSH configuration permits connection and forwarding (bear in mind
  that SSH does not allow you to forward privileged ports, i.e. < 1024, unless you log in
  as root, which is not recommended)
* Ensure that the remote configuration does not allow shell login or command execution. This
  can be done with special options in authorized_keys file.
* Log in as the tunnel user manually once, in order to authorize the remote host fingerprint
  to be added to known_hosts, or otherwise create the known_hosts entry. **Do not disable the host fingerprint verification, this
  is inherently insecure and defeats the purpose of having a SSH tunnel**

The required parameters for `autossh::tunnel` are `host` and `remote_user`, as well as at least one of `local_forwards`, `remote_forwards` or `dynamic_forwards`. The latter
correspond to SSH's parameters -L, -R and -D and can be either a single string or an array of strings.

The following elaborate example will create a tunnel that:

* Connects from the target node (local) user `tunnel` using its private key to remote SSH server `ssh.invalid.org` as remote user `tunnels_only`
* Forwards the connections to local port 1234 to 127.0.0.1:1234 and to port 1235 to machine 192.168.1.235:1235 on the remote 
* Forwards the connections to remote interface 192.168.1.33:3333 to local 10.0.1.3:3030

```
autossh::tunnel { 'my-shiny-new-tunnel':
                # Autossh will run as this local user
                user => 'tunnel',
                # Remote user to connect as 
                remote_user => 'tunnels_only'
                # SSH server address
                remote_host => 'ssh.invalid.org',
		local_forwards => [ '1234:127.0.0.1:1234', '1235:192.168.1.235:1235' ],
		remote_forwards => '192.168.1.3333:3333:10.0.1.3:3030' 
}

```
