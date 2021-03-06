## Nginx with http/3 quiche

- Nginx v1.16.1

https://hub.docker.com/r/raniellyf/nginx-http3

```sh
$ docker pull raniellyf/nginx-http3:latest
```

```
http {
    server {
        # Enable QUIC and HTTP/3.
        listen 443 quic reuseport;

        # Enable HTTP/2 (optional).
        listen 443 ssl http2;

        ssl_certificate      cert.crt;
        ssl_certificate_key  cert.key;

        # Enable all TLS versions (TLSv1.3 is required for QUIC).
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;

        # Request buffering in not currently supported for HTTP/3.
        proxy_request_buffering off;

        # Add Alt-Svc header to negotiate HTTP/3.
        add_header alt-svc 'h3-29=":443"; ma=86400';
    }
}
```
