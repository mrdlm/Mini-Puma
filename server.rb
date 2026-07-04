require "socket"
require "stringio"

# ==============================================================================
# Server - Loads and evaluates config.ru files
# ==============================================================================

class Server
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

app = Server.load_file("config.ru")

REASONS = { 200 => "OK", 404 => "NOT FOUND" }

server = TCPServer.new("127.0.0.1", 9292)
puts "Server listening on http://127.0.0.1:9292"

# ==============================================================================
# Main Request Loop
# ==============================================================================

loop do
  client = server.accept

  Thread.new(client) do |conn|
    puts "[Thread #{Thread.current.object_id}] Starting request"

    begin
      request_line = conn.gets  
      next conn.close if request_line.nil?

      # Parse HTTP request line
      method, target, _version = request_line.split(" ")
      path, query = target.split("?", 2)
      query ||= ""

      # Key-value pairs: headers["Content-Type"] = "application/json"
      headers = {}
      while (line = conn.gets) && line != "\r\n"
        key, value = line.split(": ", 2)
        headers[key] = value.strip if value
      end

      body_data = ""

      if headers["Content-Length"]
        content_length = headers["Content-Length"].to_i

        body_data = conn.read(content_length) if content_length > 0
      end 
      
      # Build Rack environment
      env = {
        "REQUEST_METHOD" => method,
        "PATH_INFO"      => path,
        "QUERY_STRING"   => query,
        "SERVER_NAME"    => "127.0.0.1",
        "SERVER_PORT"    => "9292",
        "rack.input"     => StringIO.new(body_data),
        "rack.errors"    => $stderr,
        "rack.url_scheme" => "http"
      }

      # Add HTTP headers to env (Rack spec)
      headers.each do |key, value|
        # Special cases: Content-Type and Content-Length don't get HTTP_ prefix
        env_key = case key
        when "Content-Type"
          "CONTENT_TYPE"
        when "Content-Length"
          "CONTENT_LENGTH"
        else
          # Convert "User-Agent" to "HTTP_USER_AGENT"
          "HTTP_#{key.upcase.gsub('-', '_')}"
        end
        env[env_key] = value
      end

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
      conn.write(out)  

      conn.close
      puts "[Thread #{Thread.current.object_id}] Request completed: #{method} #{path}"
    rescue => e
      puts "[Thread #{Thread.current.object_id}] Error: #{e.message}"
      puts e.backtrace.first(5).join("\n")  # Show first 5 lines of backtrace
      conn.close
    end 
  end 
end 
