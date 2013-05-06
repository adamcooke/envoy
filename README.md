# Envoy

A clone of proxylocal. Both client and server are included.

## The client

    envoyc [--host HOST] [--tls] [--server SERVER] [[ADDRESS:]PORT] 

Makes the HTTP* service running at ADDRESS:PORT available via a proxylocal
service running on SERVER. The default server is p45.eu, and the default address
and port are 127.0.0.1 and 80.

By default, the service will be available on a randomly generated domain name.
e.g. 4iur.p45.eu. To specify the first component of the name, use the HOST
argument.

## The server

    envoys [--listen [HOST:]PORT] ZONE 

Starts a proxylocal-compatible server. Listens for HTTP requests on the
specified host and port, which default to 0.0.0.0 and 8080.

The ZONE specifies the domain name suffix.
