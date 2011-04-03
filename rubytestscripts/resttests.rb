#! /opt/local/bin/ruby

require "net/http"
require "net/https"
require "rubygems"
require "restclient"

Net::HTTP.version_1_1
pem = File.read("/Users/usmanghani/Documents/apicert.pem")
cert = OpenSSL::X509::Certificate.new(pem)
key = OpenSSL::PKey::RSA.new(pem, "rdPa$$w0rd")
puts cert.inspect
puts key.inspect

# exit

response = 
  RestClient::Request.execute(:method => :get, 
  :url => "https://management.core.windows.net:443/993ad3b2-f875-4311-8459-414334cd16ee/locations",
  :headers => { "x-ms-version" => "2010-10-28", "Content-Type" => "application/xml" },
  :ssl_client_cert => OpenSSL::X509::Certificate.new(pem),
  :ssl_client_key => OpenSSL::PKey::RSA.new(pem),
  :verify_ssl => false)

puts response

# http = Net::HTTP.new("management.core.windows.net", port = 443)
# http.use_ssl = true
# http.cert = cert
# http.key = key
# http.verify_mode = OpenSSL::SSL::VERIFY_NONE
# http.read_timeout = 30
# http.start() do |http|
#   request = Net::HTTP::Get.new("/993ad3b2-f875-4311-8459-414334cd16ee/services/hostedservices")
#   request["x-ms-version"] = "2010-10-28"
#   request["Content-Type"] = "application/xml"
#   response = http.request(request)
#   puts response.body
# end


