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

        until client.eof?
          line = client.readline

          if http?(line)
            @logger.info "CapitalServer: recvd http: #{line}"

            @callback.call(parse_request(line))
          else
            @logger.info "CapitalServer: recvd: #{line}"

            response = line.upcase

            @logger.info "CapitalServer: sending: #{response}"
            client.puts line.upcase
          end
        end
      end
    end
  end

  def parse_request(line)
    method, target, version = line.split(/\s/)

    { method: method, target: target, version: version }
  end
  
  def http?(line)
    line.include?("HTTP/1.1")
  end

  def stop
    @thread.kill
    @server.close
  end
end
