require "socket" 

server = TCPServer.new("127.0.0.1", 9292)
puts "Server running on 127.0.0.1 and port 9292"


loop do
  client = server.accept  
  request = client.readpartial(4096)
  body = "hello\n"

  client.write(
    "HTTP/1.1 200 OK\r\n"                     \
    "Content-Type: text/plain\r\n"            \
    "Content-Length: #{body.bytesize}\r\n"    \
    "Connection: close\r\n"                   \
    "\r\n"                                    \
    "#{body}"
  )

  client.close
end

