vcl 4.1;
import dynamic;
backend default none;

sub vcl_init {
    new d = dynamic.director(port = "80", ttl = 60s);
}

sub vcl_recv {
    if (req.http.X-Forwarded-Proto !~ "(?i)https") { 
        return (synth(10301, "Moved Permanently")); 
    }
}
sub vcl_synth {
    if (resp.status == 10301) {
        set resp.status = 301;
        set resp.http.Location = "https://" + req.http.host + req.url;
        return(deliver);
    }
}

sub vcl_recv {
    set req.backend_hint = d.backend("webapp-service"); # Replace this value with the name of the service linked to your app
    return (hash);
}

sub vcl_backend_response {
    set beresp.ttl = 600s;
    unset beresp.http.set-cookie;
    return (deliver);
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.Varnish-Cache = "HIT";
    } else {
        set resp.http.Varnish-Cache = "MISS";
    }
}

sub vcl_hash {
    hash_data(req.http.X-Forwarded-Proto);
}
