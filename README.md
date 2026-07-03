# Mini-Puma

A minimal Rack-compatible HTTP server built from scratch in ~70 lines of Ruby.

## About

This project is a learning exercise to understand how web servers work by building a simplified version of Puma from the ground up. It implements the core functionality of a production web server: TCP socket handling, HTTP parsing, Rack interface, and request/response cycle.

## What Works ✅

- **TCP Socket Server** - Accepts connections on port 9292
- **HTTP/1.1 Parsing** - Parses request line (method, path, query string)
- **Rack Interface** - Loads and executes `config.ru` files via `instance_eval`
- **Rack Environment** - Builds proper `env` hash with required keys
- **Application Execution** - Calls Rack apps and handles responses
- **HTTP Response Building** - Formats status line, headers, and body
- **Multiple Routes** - Supports routing via Rack applications
- **Query Parameters** - Parses and passes query strings
- **POST Requests** - Handles POST method (body parsing basic)

## What's NOT Implemented (Yet) 🚧

### High Priority
- **Concurrency** - Single-threaded (handles one request at a time)
- **Request Body Parsing** - Only reads headers, doesn't parse POST bodies properly
- **Header Parsing** - Headers are discarded instead of being added to `env` hash
- **Keep-Alive** - Closes connection after each request (no HTTP/1.1 persistent connections)

### Medium Priority
- **Better Error Handling** - Crashes on malformed requests
- **Chunked Transfer Encoding** - Doesn't support chunked requests/responses
- **SSL/TLS** - No HTTPS support
- **Logging** - Minimal logging of requests

### Low Priority (Advanced)
- **Graceful Shutdown** - No signal handling
- **Worker Processes** - No clustering/forking
- **Configuration System** - Hardcoded host/port
- **Performance Optimizations** - No C extensions like real Puma

## Getting Started

### Run the Server

```bash
ruby rackbuilder.rb
```

The server will start on `http://127.0.0.1:9292`

### Test Routes

```bash
# Home page
curl http://localhost:9292/

# About page
curl http://localhost:9292/about

# JSON API
curl http://localhost:9292/api/hello?name=Ruby

# POST request
curl -X POST http://localhost:9292/submit -d "message=Hello"
```

## Project Structure

```
.
├── rackbuilder.rb  # Main HTTP server (Mini-Puma)
├── config.ru       # Rack configuration
├── app.rb          # Sample Rack application
├── README.md       # This file
└── notes/          # Learning notes and references
    ├── examples_other_languages.md
    └── rack_vs_wsgi.md
```

## How It Works

1. **TCP Socket** - Listen for connections using `TCPServer`
2. **Accept Connection** - Wait for client to connect
3. **Parse HTTP Request** - Read request line and headers
4. **Build Rack Env** - Create environment hash per Rack spec
5. **Load Rack App** - Execute `config.ru` with `instance_eval`
6. **Call App** - `app.call(env)` returns `[status, headers, body]`
7. **Format Response** - Build HTTP response string
8. **Send & Close** - Write response and close connection

## Next Steps

Potential improvements in order of impact:

1. **Add Threading** - Use `Thread.new` to handle concurrent requests
2. **Parse Request Headers** - Add headers to env hash as `HTTP_*` keys
3. **Handle Request Bodies** - Read POST data using `Content-Length`
4. **Keep-Alive Support** - Reuse connections for multiple requests
5. **Better HTTP Parsing** - Handle edge cases and malformed requests

## References

- [Puma Web Server](https://github.com/puma/puma) - The real thing
- [Rack Specification](https://github.com/rack/rack/blob/main/SPEC.rdoc) - Rack interface spec
- [HTTP/1.1 RFC 9112](https://www.rfc-editor.org/rfc/rfc9112.html) - HTTP protocol
- [Socket Programming in Ruby](https://ruby-doc.org/stdlib/libdoc/socket/rdoc/Socket.html)

## What I Learned

- HTTP is just formatted text with `\r\n` line endings
- Rack is a simple contract: `env` hash → `[status, headers, body]`
- Web servers are TCP socket listeners that parse/build HTTP
- The same concepts work across all languages (Python WSGI, Java Servlets, etc.)
- Production servers add optimization, not fundamentally different logic
