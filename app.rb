require "sinatra"
require "sinatra/multi_route"
require "socket"
require "json"
require "securerandom"
require "base64"



server = TCPServer.open(4000)
client = nil

responses = {}
Thread.new do
  client = server.accept
  while line = client.gets
    response_pack = JSON.parse line
    responses[response_pack['request']['id']] = response_pack
  end
  client.close
  server = nil
end

route :get, :post, :put, :patch, :delete, :options, :link, :unlink, "*" do
  if client.nil?
    halt 500, 'Client not available'
  end

  id = SecureRandom.uuid
  client.puts JSON.generate(:id => id, :method => request.env["REQUEST_METHOD"], :path => params['splat'][0], :params => params)

  i = 0
  while !responses.has_key?(id)
    sleep 0.05
    i+=1
    if i > 200
      halt 408, 'Timeout'
    end
  end

  response = responses[id]['response']
  headers response['headers']
  halt response['status'], Base64.decode64(response['body'])
end
