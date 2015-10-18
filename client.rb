require "faraday"
require "socket"
require "json"
require "base64"

conn = Faraday.new(:url => 'http://localhost:9000') do |faraday|
  faraday.request  :url_encoded             # form-encode POST params
  faraday.response :logger                  # log requests to STDOUT
  faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
end

while true do
  begin
    socket = TCPSocket.open('localhost',4000)
    puts "Connection successful"

    while line = socket.gets
      begin
        request = JSON.parse line.chomp
        response = conn.send(request['method'].downcase,request['path'],request['params'])
        puts socket.puts JSON.generate({'request' => request, 'response' => {'body' =>  Base64.encode64(response.body), 'status' => response.status, 'headers' => response.headers}})
      rescue => e
        puts e.message
      end
    end
    socket.close
  rescue => e
    puts e.message
    sleep 0.1
  end

end
