# A real Rack application class
# This is how frameworks like Rails and Sinatra work under the hood
# q: so, wait, it's just a regular class? but with a call method? 
class MyApp
  # ESSENTIAL: Rack requires a #call method that takes env and returns [status, headers, body]
  def call(env)
    # Extract request information from Rack env hash
    request_method = env['REQUEST_METHOD']
    path = env['PATH_INFO']
    query_string = env['QUERY_STRING']

    # Simple routing based on path and method
    case [request_method, path]
    when ['GET', '/']
      home_page
    when ['GET', '/about']
      about_page
    when ['GET', '/api/hello']
      api_response(query_string)
    when ['POST', '/submit']
      handle_form(env)
    else
      not_found
    end
  end

  private

  # Home page handler
  def home_page
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>My Real Rack App</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; }
          a { color: #0066cc; margin-right: 15px; }
          pre { background: #f4f4f4; padding: 10px; }
        </style>
      </head>
      <body>
        <h1>Welcome to My Real Rack App! 🚀</h1>
        <p>This is a proper Rack application class, not just a lambda.</p>

        <h2>Available Routes:</h2>
        <ul>
          <li><a href="/">GET /</a> - This page</li>
          <li><a href="/about">GET /about</a> - About page</li>
          <li><a href="/api/hello?name=Ruby">GET /api/hello?name=Ruby</a> - JSON API</li>
          <li>POST /submit - Form submission (try curl)</li>
        </ul>

        <h2>Request Information:</h2>
        <p><strong>Server:</strong> Mini-Puma</p>
        <p><strong>App Class:</strong> MyApp</p>

        <h3>Try the API:</h3>
        <pre>curl http://localhost:9292/api/hello?name=Ruby</pre>

        <h3>Try POST:</h3>
        <pre>curl -X POST http://localhost:9292/submit -d "message=Hello from curl"</pre>
      </body>
      </html>
    HTML

    # Return Rack response: [status, headers, body]
    [200, {'Content-Type' => 'text/html'}, [html]]
  end

  # About page handler
  def about_page
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head><title>About - My App</title></head>
      <body>
        <h1>About This App</h1>
        <p>This is a class-based Rack application.</p>
        <p>It implements the Rack interface by providing a #call method.</p>
        <p><a href="/">← Back to Home</a></p>
      </body>
      </html>
    HTML

    [200, {'Content-Type' => 'text/html'}, [html]]
  end

  # JSON API handler
  def api_response(query_string)
    # Parse query string manually (no CGI for simplicity)
    params = {}
    if query_string && !query_string.empty?
      query_string.split('&').each do |pair|
        key, value = pair.split('=', 2)
        params[key] = value
      end
    end

    name = params['name'] || 'World'

    # Return JSON response
    json = {
      message: "Hello, #{name}!",
      timestamp: Time.now.to_s,
      app: "MyApp",
      query_params: params
    }

    # Manually build JSON (or use require 'json' in a real app)
    json_string = "{\n"
    json_string += "  \"message\": \"#{json[:message]}\",\n"
    json_string += "  \"timestamp\": \"#{json[:timestamp]}\",\n"
    json_string += "  \"app\": \"#{json[:app]}\",\n"
    json_string += "  \"query_params\": #{params.inspect}\n"
    json_string += "}"

    [200, {'Content-Type' => 'application/json'}, [json_string]]
  end

  # Form submission handler
  def handle_form(env)
    # Read POST body
    body = env['rack.input'].read

    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head><title>Form Submitted</title></head>
      <body>
        <h1>Form Received! ✓</h1>
        <p><strong>POST data received:</strong></p>
        <pre>#{body}</pre>
        <p><a href="/">← Back to Home</a></p>
      </body>
      </html>
    HTML

    [200, {'Content-Type' => 'text/html'}, [html]]
  end

  # 404 handler
  def not_found
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head><title>404 Not Found</title></head>
      <body>
        <h1>404 - Page Not Found</h1>
        <p>The page you're looking for doesn't exist.</p>
        <p><a href="/">← Back to Home</a></p>
      </body>
      </html>
    HTML

    [404, {'Content-Type' => 'text/html'}, [html]]
  end
end
