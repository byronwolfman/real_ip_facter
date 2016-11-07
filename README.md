# Consume CDN IP Addresses through Facter

## What is this?

I'm prepping a new webhost to be served behind Cloudflare. Cloudflare advices that you will need to implement the `real_ip` module if you use nginx and want to know where your traffic is really coming from. The method to do so is described here:

https://support.cloudflare.com/hc/en-us/articles/200170706-How-do-I-restore-original-visitor-IP-with-Nginx-

Below the list of Cloudflare IP addresses is the following caveat:

> NB: That list of prefixes needs to be updated regularly

It's unclear what the frequency of "regularly" is, but it sure would be nice to not have to worry about it. I originally solved this problem with a big pile of bash -- you can see what that looked like [over here](https://github.com/byronwolfman/real_ip_hydrator) (but TL;DR: it grabs and parses Cloudflare's published list of IPv4 and IPv6 addresses and shoves them into an nginx config). This was all well and good but I worried that the script and puppet might clobber each other, and anyway, it doesn't seem fantastic to have two different things managing nginx's configuration.

Now, if puppet could consume that information as a fact, we'd be cooking.

## How it works

Hopefully the script is easy to parse, but just in case it isn't, here's what it does:

1. Downloads a list of return-delimited IPv4 and IPv6 addresses from Cloudflare
1. Validates the list through a couple of very ugly (but accurate) regexes
1. Returns the arrays `cloudflare_ipv4s` and `cloudflare_ipv6s` to facter to be used as you see fit.

## How to use it with facter

If you're not using puppet and just want to use facter, you can consume it like so:

    facter --custom-dir /path/to/cloudflare_ips.rb

## How to use it with puppet

It probably makes sense to associate the fact with the module that will consume it. In my case this is the nginx module, so the script itself is located in

    modules/nginx/lib/facter/cloudflare_ips.rb

Next consume the fact in nginx's params.pp manifest:

    $cloudflare_ipv4s = $facts['cloudflare_ipv4s']
    $cloudflare_ipv6s = $facts['cloudflare_ipv6s']

Finally, render the arrays into a template:

    <% scope['nginx::params::cloudflare_ipv4s'].each do |ip| -%>
    set_real_ip_from <%= ip %>;
    <% end -%>

    <% scope['nginx::params::cloudflare_ipv6s'].each do |ip| -%>
    set_real_ip_from <%= ip %>;
    <% end -%>

    real_ip_header X-Forwarded-For;

Alternatively you can access the facts in the template directly as a top-level variable, i.e. `scope['::cloudflare_ipv4s']` and skip on adding it to the params.pp manifest. This is fine and it works, but you lose out on the means to perform validation within the manifests (you could do validation in the templates themselves but this is ugly).

## Danger

This script makes certain assumptions which may cause you grief:

- The script assumes return-delimited lists
- The script assumes you are using Cloudflare (but Fastly might make an appearance in the future!)
- The script returns an empty array to facter if it can't download the lists

Use/modify/deploy at your own risk.

## Contributing

Feel free to fork and make pull requests.
