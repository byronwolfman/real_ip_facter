# Download the list of Fastly IPv4 and IPv6 addresses used by their CDN for
# proxying requests and provide that information in the form of facter arrays.
# In the event that the addresses cannot be retrieved, facter will output an
# empty array for each.

# Paired with nginx's real_ip module, this is a handy way to correctly log
# visitor traffic, rather than logging the CDN itself as the visitor. See:
# https://docs.fastly.com/guides/securing-communications/accessing-fastlys-ip-ranges

require 'facter'
require 'json'
require 'net/http'
require 'openssl'

# IPv4 regex found via http://www.regexpal.com/93987 on 2016-09-24
# IPv6 regex found via http://www.regexpal.com/93988 on 2016-09-24
ipv4_regex = /([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?/
ipv6_regex = /s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:)))(%.+)?s*(\/([0-9]|[1-9][0-9]|1[0-1][0-9]|12[0-8]))?/

Facter.add(:fastly_ipv4s) do
  setcode do
    http = Net::HTTP.new('api.fastly.com', 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    response = http.request_get('/public-ip-list')
    JSON.parse(response.body)['addresses'].select do |ip|
      ip =~ ipv4_regex
    end
  end
end

# Note that at the time of writing (Nov 10 2016), Fastly's CDN only uses (or at
# least only publishes) IPv4 addresses. Therefore the expected output here is an
# empty array. The block below exists pre-emptively, should this change.
Facter.add(:fastly_ipv6s) do
  setcode do
    http = Net::HTTP.new('api.fastly.com', 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    response = http.request_get('/public-ip-list')
    JSON.parse(response.body)['addresses'].select do |ip|
      ip =~ ipv6_regex
    end
  end
end
