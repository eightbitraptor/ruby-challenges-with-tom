require 'socket'
require 'logger'

class CapitalServer
  attr_reader :request

  def initialize(port, logger = Logger.new(STDERR))
    @server = TCPServer.new(port)
    @logger = logger
  end

  def on_request(&block)
    @callback = block
  end

  def start
    @thread = Thread.new do
      loop do
        client = @server.accept

        request = []
        until client.eof?
          line = client.readline

          if @http || http?(line)
            @logger.info "CapitalServer: recvd http: #{line}"
            @http = true
            request << line
          else
            @logger.info "CapitalServer: recvd: #{line}"

            response = line.upcase

            @logger.info "CapitalServer: sending: #{response}"
            client.puts line.upcase
          end
        end

        @callback.call(parse_request(request)) if @http
      end
    end
  end

  def parse_request(request)
    request_line = request.shift
    method, target, version = request_line.split(/\s/)

    headers = {}
    loop do
      line = request.shift.chomp
      break if line.empty?
      header, value = line.split(':')
      headers[header] = value.strip
    end

    { method: method, target: target, version: version, 
      headers: headers, body: request.join.chomp }
  end
  
  def http?(line)
    line.include?("HTTP/1.1")
  end

  def stop
    @thread.kill
    @server.close
  end
end
