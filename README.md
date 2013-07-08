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
