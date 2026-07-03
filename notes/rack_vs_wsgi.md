# Rack vs WSGI: Side-by-Side Comparison

## Quick Answer

**WSGI (Web Server Gateway Interface)** is Python's version of Rack.

They do the **exact same thing**: provide a standard interface between web servers and applications.

---

## Side-by-Side: Application Code

### Ruby (Rack)

```ruby
# app.rb
class MyApp
  def call(env)
    status = 200
    headers = {"Content-Type" => "text/html"}
    body = ["<h1>Hello from Rack!</h1>"]
    
    # Return everything as array
    [status, headers, body]
  end
end
```

### Python (WSGI)

```python
# app.py
def wsgi_app(environ, start_response):
    status = '200 OK'
    headers = [('Content-Type', 'text/html')]
    body = [b'<h1>Hello from WSGI!</h1>']
    
    # Call callback first, then return body
    start_response(status, headers)
    return body
```

**Key Difference:**
- **Rack**: Returns `[status, headers, body]` all together
- **WSGI**: Calls `start_response(status, headers)` then returns `body`

---

## Side-by-Side: Server Code

### Ruby (Your Mini-Puma)

```ruby
# rackbuilder.rb
app = MiniRackBuilder.load_file("config.ru")

server = TCPServer.new("127.0.0.1", 9292)

loop do
  client = server.accept
  request_line = client.gets
  method, target, version = request_line.split(" ")
  
  # Build Rack env hash
  env = {
    "REQUEST_METHOD" => method,
    "PATH_INFO" => path,
    "QUERY_STRING" => query,
    # ... more keys
  }
  
  # Call Rack app
  status, headers, body = app.call(env)
  
  # Build HTTP response
  out = "HTTP/1.1 #{status} OK\r\n"
  headers.each { |k, v| out << "#{k}: #{v}\r\n" }
  # ... send response
end
```

### Python (Mini WSGI Server)

```python
# wsgi_server.py
app = load_wsgi_app()

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind(("127.0.0.1", 9292))
server.listen(5)

while True:
    client, addr = server.accept()
    request = client.recv(4096).decode('utf-8')
    method, target, version = request.split('\r\n')[0].split(' ')
    
    # Build WSGI environ dict (SAME keys as Rack!)
    environ = {
        'REQUEST_METHOD': method,
        'PATH_INFO': path,
        'QUERY_STRING': query,
        # ... more keys
    }
    
    # Call WSGI app
    response_body = app(environ, start_response_callback)
    
    # Build HTTP response (same as Ruby!)
    response = f"HTTP/1.1 {status}\r\n"
    for name, value in headers:
        response += f"{name}: {value}\r\n"
    # ... send response
```

**Notice:** The environ/env dict uses **the same keys**! Both follow the CGI standard.

---

## The environ/env Dictionary Keys

Both Rack and WSGI use the **same keys** (inherited from CGI):

| Key | Rack | WSGI | Example Value |
|-----|------|------|---------------|
| Request method | `REQUEST_METHOD` | `REQUEST_METHOD` | `"GET"` |
| Path | `PATH_INFO` | `PATH_INFO` | `"/users/123"` |
| Query string | `QUERY_STRING` | `QUERY_STRING` | `"name=bob"` |
| Server name | `SERVER_NAME` | `SERVER_NAME` | `"localhost"` |
| Server port | `SERVER_PORT` | `SERVER_PORT` | `"9292"` |
| Request body | `rack.input` | `wsgi.input` | IO object |
| Error stream | `rack.errors` | `wsgi.errors` | stderr |
| URL scheme | `rack.url_scheme` | `wsgi.url_scheme` | `"http"` |

**The keys are 99% the same!** Only the namespace differs (`rack.*` vs `wsgi.*`).

---

## Real-World Usage

### Ruby Ecosystem

**Rack Servers:**
- Puma (what you studied!)
- Unicorn
- Thin
- Passenger

**Rack Apps/Frameworks:**
- Rails
- Sinatra
- Roda
- Hanami

**How it works:**
```ruby
# config.ru
require 'sinatra'

get '/' do
  "Hello World"
end

run Sinatra::Application
```

Run with: `puma config.ru` or `thin start` or `unicorn config.ru`

---

### Python Ecosystem

**WSGI Servers:**
- Gunicorn (like Puma - production-ready)
- uWSGI (high performance)
- Waitress (pure Python)
- mod_wsgi (Apache module)

**WSGI Apps/Frameworks:**
- Django
- Flask
- FastAPI (also supports ASGI)
- Pyramid

**How it works:**
```python
# app.py
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello World"

# app is a WSGI application!
```

Run with: `gunicorn app:app` or `uwsgi --http :8000 --wsgi-file app.py`

---

## History

### Timeline

- **1993**: CGI (Common Gateway Interface) - The original standard
- **2003**: WSGI (PEP 333) - Python standardizes web interface
- **2007**: Rack - Ruby learns from WSGI and improves the API
- **2019**: ASGI - Python adds async support (modern alternative to WSGI)

### Why WSGI API is awkward

**WSGI (2003) - Two-step process:**
```python
def app(environ, start_response):
    start_response('200 OK', headers)  # Step 1: Set status/headers
    return [body]                       # Step 2: Return body
```

**Rack (2007) - Simplified:**
```ruby
def call(env)
  [200, headers, body]  # Return everything at once!
end
```

**Why?** WSGI was designed to support streaming before Python had good streaming primitives. Rack learned from this and simplified the API.

---

## Modern Alternatives

### Python: ASGI (Async)

**For async/await apps:**
```python
async def app(scope, receive, send):
    await send({
        'type': 'http.response.start',
        'status': 200,
        'headers': [(b'content-type', b'text/plain')],
    })
    await send({
        'type': 'http.response.body',
        'body': b'Hello World',
    })
```

**Servers:** Uvicorn, Hypercorn, Daphne

---

### Node.js: Built-in HTTP

**Node doesn't need WSGI/Rack because HTTP is in the standard library:**
```javascript
const http = require('http');

http.createServer((req, res) => {
    res.writeHead(200, {'Content-Type': 'text/html'});
    res.end('<h1>Hello World</h1>');
}).listen(8000);
```

---

### Go: net/http

**Go also has HTTP in stdlib:**
```go
func handler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "text/html")
    fmt.Fprintf(w, "<h1>Hello World</h1>")
}

http.ListenAndServe(":8000", http.HandlerFunc(handler))
```

---

## Summary Table

| Language | Interface | Year | Servers | Frameworks |
|----------|-----------|------|---------|------------|
| **Ruby** | Rack | 2007 | Puma, Unicorn | Rails, Sinatra |
| **Python** | WSGI | 2003 | Gunicorn, uWSGI | Django, Flask |
| **Python** | ASGI | 2019 | Uvicorn, Hypercorn | FastAPI, Starlette |
| **Java** | Servlet | 1997 | Tomcat, Jetty | Spring, Struts |
| **PHP** | FastCGI | ~2000 | PHP-FPM | Laravel, Symfony |
| **Node.js** | Built-in | 2009 | - | Express, Koa |
| **Go** | Built-in | 2009 | - | Gin, Echo |

---

## The Core Idea (Universal)

All of these do the same thing:

```
1. Define standard interface
2. Server builds environ/env/request dict
3. Server calls app with environ
4. App returns status/headers/body
5. Server formats HTTP response
6. Server sends to client
```

**Your Mini-Puma taught you the universal pattern!** 🎉

The only difference is the specific API (return array vs callback, etc).
