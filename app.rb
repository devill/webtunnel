require "sinatra"
require "socket"
require "json"
require "securerandom"
require "base64"


server = TCPServer.open(4000)
client = server.accept

responses = {}
Thread.new do
  while line = client.gets
    response_pack = JSON.parse line
    responses[response_pack['request']['id']] = response_pack
  end
end

get "*" do
  id = SecureRandom.uuid
  client.puts JSON.generate(:id => id, :method => 'GET', :path => params['splat'][0])

  while !responses.has_key?(id)
    sleep 0.05
  end

  response = responses[id]['response']
  headers response['headers']
  halt response['status'], Base64.decode64(response['body'])
end
