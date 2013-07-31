# Envoy

A clone of proxylocal. Both client and server are included.

    gem install envoy-proxy

## The client

    envoy [--key KEY] [--host HOST] [--tls] [--server SERVER] [[ADDRESS:]PORT] 

Makes the HTTP* service running at ADDRESS:PORT available via a proxylocal
service running on SERVER. The default server is p45.eu, and the default address
and port are 127.0.0.1 and 80.

By default, the service will be available on a randomly generated domain name.
e.g. 4iur.p45.eu. To specify the first component of the name, use the HOST
argument.

You can connect multiple clients to the same host name. To help prevent abuse,
each client must present the KEY.

## The server

    envoyd [--key KEY] [--listen [HOST:]PORT] ZONE 

Starts a proxylocal-compatible server. Listens for HTTP requests on the
specified host and port, which default to 0.0.0.0 and 8080.

If KEY is specified, clients _must_ specify that key.

The ZONE specifies the domain name suffix.

## Advanced Client Configuration

The client will search up from the current directory for a .envoy file. If it
exists, it must be a YAML file containing either one hash of command line
options, or an array of multiple options. If an array is passed, the client
will proxy multiple local services.

This file can also contain settings which will execute a command if a local
connection is refused.

    Option         Description                                        Default
    ---------------------------------------------------------------------------
    host           The domain name prefix                             None
    local_port     The local port to use                              None
    local_host     The local host to use                              127.0.0.1
    server_host    The server host to use                             p45.eu
    server_port    The server port to use                             8282
    tls            Use TLS in the server connections                  false
    verbose        Be noisy                                           false
    command        A command to run if a local connection is refused  None
    command_delay  Number of seconds to wait before reconnecting,     1
                   after starting a command
    dir            A directory to change to                           None

If no host is specified, a random one is selected by the server.
If no local port is specified, a random one is selected by the client.
The command is processed for % substitions against the configuration hash,
including any randomly selected local port.

e.g. To start a set of rails apps, you might use this configuration:

    - host: backend
      dir: ~/apps/backend
      command: rails s -p %{local_port}
    - host: frontend
      dir: ~/apps/frontend
      command: rails s -p %{local_port}

You can still specify a constant local port, if you prefer that.

