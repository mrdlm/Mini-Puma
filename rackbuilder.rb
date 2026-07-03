require "socket"
require "stringio"

# ==============================================================================
# Rack Builder - Loads and evaluates config.ru files
# ==============================================================================

class MiniRackBuilder
  def self.load_file(path)
    b = new
    b.instance_eval(File.read(path), path)
    b.to_app
  end

  def run(app) = @app = app
  def to_app = @app
end

# ==============================================================================
# Setup
# ==============================================================================

app = MiniRackBuilder.load_file("config.ru")

REASONS = { 200 => "OK", 404 => "NOT FOUND" }

server = TCPServer.new("127.0.0.1", 9292)
puts "Server listening on http://127.0.0.1:9292"

# ==============================================================================
# Main Request Loop
# ==============================================================================

loop do
  client = server.accept
  request_line = client.gets
  next client.close if request_line.nil?

  # Parse HTTP request line
  method, target, _version = request_line.split(" ")
  path, query = target.split("?", 2)
  query ||= ""

  # Skip headers until blank line
  while (line = client.gets) && line != "\r\n"; end

  # Build Rack environment
  env = {
    "REQUEST_METHOD" => method,
    "PATH_INFO"      => path,
    "QUERY_STRING"   => query,
    "SERVER_NAME"    => "127.0.0.1",
    "SERVER_PORT"    => "9292",
    "rack.input"     => StringIO.new(""),
    "rack.errors"    => $stderr,
    "rack.url_scheme" => "http"
  }

  # Call Rack app
  status, headers, body = app.call(env)

  # Collect response body
  data = +""
  body.each { |chunk| data << chunk }
  body.close if body.respond_to?(:close)

  # Build HTTP response
  reason = REASONS[status] || "OK"
  out = +"HTTP/1.1 #{status} #{reason}\r\n"

  headers.each { |k, v| out << "#{k}: #{v}\r\n" }
  out << "Content-Length: #{data.bytesize}\r\n"
  out << "Connection: close\r\n\r\n"
  out << data

  # Send response and close
  client.write(out)
  client.close
end 
