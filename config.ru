# Load our real Rack application
require_relative 'app'

# Run the MyApp class
# Rack will call MyApp.new.call(env) for each request
run MyApp.new
