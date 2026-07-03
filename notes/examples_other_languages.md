# HTTP Server Across Languages (Without Frameworks)

## 1. Python (No Framework - Pure Sockets)

```python
import socket

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind(("127.0.0.1", 9292))
server.listen(5)
print("Server listening on 9292")

while True:
    client, addr = server.accept()
    
    # Read HTTP request (same as Ruby client.gets)
    request = client.recv(4096).decode('utf-8')
    
    # Parse first line
    lines = request.split('\r\n')
    method, path, version = lines[0].split(' ')
    
    # Build HTTP response (same format!)
    response = "HTTP/1.1 200 OK\r\n"
    response += "Content-Type: text/html\r\n"
    response += "\r\n"
    response += "<h1>Hello from Python!</h1>"
    
    client.send(response.encode('utf-8'))
    client.close()
```

**Same concepts as your Ruby code!**
- Socket listen/accept
- Parse HTTP text
- Build HTTP response text
- Send it back

---

## 2. Node.js (No Framework - Pure Sockets)

```javascript
const net = require('net');

const server = net.createServer((socket) => {
  socket.on('data', (data) => {
    // Parse HTTP request (same format!)
    const request = data.toString();
    const lines = request.split('\r\n');
    const [method, path, version] = lines[0].split(' ');
    
    // Build HTTP response (same format!)
    const response = 
      "HTTP/1.1 200 OK\r\n" +
      "Content-Type: text/html\r\n" +
      "\r\n" +
      "<h1>Hello from Node.js!</h1>";
    
    socket.write(response);
    socket.end();
  });
});

server.listen(9292);
console.log('Server listening on 9292');
```

**Exactly the same approach!**

---

## 3. Go (No Framework)

```go
package main

import (
    "bufio"
    "fmt"
    "net"
    "strings"
)

func main() {
    listener, _ := net.Listen("tcp", ":9292")
    fmt.Println("Server listening on 9292")
    
    for {
        conn, _ := listener.Accept()
        go handleConnection(conn)  // Go makes concurrency easy!
    }
}

func handleConnection(conn net.Conn) {
    defer conn.Close()
    
    // Read HTTP request (same format!)
    reader := bufio.NewReader(conn)
    requestLine, _ := reader.ReadString('\n')
    
    // Parse first line
    parts := strings.Split(requestLine, " ")
    method, path := parts[0], parts[1]
    
    // Build HTTP response (same format!)
    response := "HTTP/1.1 200 OK\r\n" +
               "Content-Type: text/html\r\n" +
               "\r\n" +
               "<h1>Hello from Go!</h1>"
    
    conn.Write([]byte(response))
}
```

---

## 4. C (The OG - How Everything Works Under the Hood)

```c
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>

int main() {
    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    
    struct sockaddr_in address;
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(9292);
    
    bind(server_fd, (struct sockaddr *)&address, sizeof(address));
    listen(server_fd, 3);
    printf("Server listening on 9292\n");
    
    while(1) {
        int client_fd = accept(server_fd, NULL, NULL);
        
        // Read HTTP request
        char buffer[4096] = {0};
        read(client_fd, buffer, 4096);
        
        // Build HTTP response (same format!)
        char *response = 
            "HTTP/1.1 200 OK\r\n"
            "Content-Type: text/html\r\n"
            "\r\n"
            "<h1>Hello from C!</h1>";
        
        write(client_fd, response, strlen(response));
        close(client_fd);
    }
    return 0;
}
```

**This is what Ruby/Python/Node do under the hood!**

---

# Application Interfaces (Like Rack)

Without Rack (or equivalent), every app talks directly to sockets.
With an interface, apps are portable across servers.

## Python: WSGI (Web Server Gateway Interface)

**Like Rack for Python!**

```python
# WSGI app (like your Rack app)
def application(environ, start_response):
    # environ is like Rack's env hash
    # start_response is like returning [status, headers]
    
    status = '200 OK'
    headers = [('Content-Type', 'text/html')]
    start_response(status, headers)
    
    # Return body (like Rack)
    return [b'<h1>Hello from WSGI!</h1>']

# Server code (like your Mini-Puma)
# Parse HTTP → build environ dict → call app → send response
```

**Servers that support WSGI:**
- Gunicorn (like Puma)
- uWSGI
- Waitress
- Flask's dev server

---

## Java: Servlet API

```java
public class MyServlet extends HttpServlet {
    // Like Rack's call(env)
    protected void doGet(HttpServletRequest request, 
                        HttpServletResponse response) {
        // request is like env hash
        String path = request.getPathInfo();
        
        // response is like [status, headers, body]
        response.setStatus(200);
        response.setContentType("text/html");
        response.getWriter().write("<h1>Hello from Java!</h1>");
    }
}
```

**Servers that support Servlets:**
- Tomcat (like Puma)
- Jetty
- WildFly

---

## Node.js: Built-in HTTP module

```javascript
const http = require('http');

// Node has HTTP built in!
const server = http.createServer((req, res) => {
    // req is like env hash
    const path = req.url;
    const method = req.method;
    
    // res is like [status, headers, body]
    res.writeHead(200, {'Content-Type': 'text/html'});
    res.end('<h1>Hello from Node!</h1>');
});

server.listen(9292);
```

**Node doesn't need Rack-like interface because HTTP is built into the language!**

---

## Go: net/http package

```go
package main

import (
    "fmt"
    "net/http"
)

// Handler function (like Rack's call)
func handler(w http.ResponseWriter, r *http.Request) {
    // r is like env hash (r.Method, r.URL.Path, etc.)
    // w is like [status, headers, body]
    
    w.Header().Set("Content-Type", "text/html")
    w.WriteHead(200)
    fmt.Fprintf(w, "<h1>Hello from Go!</h1>")
}

func main() {
    http.HandleFunc("/", handler)
    http.ListenAndServe(":9292", nil)
}
```

**Go also has HTTP built in!**

---

# Summary Table

| Language | Low-Level | Interface Standard | Popular Servers |
|----------|-----------|-------------------|-----------------|
| **Ruby** | Socket | **Rack** | Puma, Unicorn, Thin |
| **Python** | socket | **WSGI** | Gunicorn, uWSGI |
| **Java** | Socket | **Servlet API** | Tomcat, Jetty |
| **PHP** | socket | **FastCGI/CGI** | PHP-FPM, Apache mod_php |
| **Node.js** | net | **Built-in http** | Express uses http |
| **Go** | net | **Built-in net/http** | stdlib is the server |
| **C** | socket | **CGI (old)** | nginx, Apache (in C) |

---

# Key Insight

## What's the Same (Universal):
1. **TCP sockets** - listen/accept/read/write
2. **HTTP format** - text with `\r\n`
3. **Parse request** - method, path, headers
4. **Build response** - status line, headers, body

## What's Different (Language-specific):
1. **Application Interface**:
   - Ruby: Rack (env hash → [status, headers, body])
   - Python: WSGI (environ dict → status + headers + body)
   - Java: Servlet API (request/response objects)
   - Node/Go: Built-in HTTP (request/response objects)

## Your Mini-Puma:
- **The socket/HTTP parts**: Universal! Works same way in C/Python/Go
- **The Rack interface**: Ruby-specific! Python uses WSGI, Java uses Servlets

---

# Without Rack/WSGI/etc:

**Option 1: Direct Socket (What you showed)**
Every app must handle sockets directly:
```ruby
server = TCPServer.new(9292)
loop do
  client = server.accept
  # App code here - coupled to sockets!
end
```

**Option 2: Framework Includes Server**
Each framework bundles its own server:
- Rails would include its own HTTP parser
- Sinatra would include its own HTTP parser
- Every framework reinvents the wheel

**Why Rack/WSGI exist:**
Decouple the server from the app!
- Write app once, run on any Rack server
- Write server once, run any Rack app
- Don't reinvent HTTP parsing for every framework

---

# You've Built the Universal Part!

Your Mini-Puma's socket/HTTP code would work the same in:
- Python (replace TCPServer with socket.socket)
- Node.js (replace with net.createServer)
- Go (replace with net.Listen)
- C (replace with socket()/bind()/listen())

**The concepts you learned are universal to ALL HTTP servers!** 🌍
