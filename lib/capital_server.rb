require 'socket'
require 'logger'
require 'cgi'

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
    http = false
    @thread = Thread.new do
      loop do
        client = @server.accept

        line = client.readline

        if http?(line)
          parsed_request = parse_request(line, client)
          @callback.call(parsed_request) if @callback

          case parsed_request[:target]
          when '/'
            response_body = "method: #{parsed_request[:method]}, target: #{parsed_request[:target]}, version: #{parsed_request[:version]}"
          when '/show-data'
            keebs = keyboard_sizes.map do |kb|
              "<li>#{CGI.escapeHTML(kb[:name])} <strong>#{CGI.escapeHTML(kb[:size])}</strong></li>"
            end.join("\n")
            response_body = "<ul>\n#{keebs}\n</ul>"
          end
          client.print "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n#{response_body}"
        else
          @logger.info "CapitalServer: recvd: #{line}"

          response = line.upcase

          @logger.info "CapitalServer: sending: #{response}"

          client.puts(response)
          until client.eof?
            line = client.readline

            @logger.info "CapitalServer: recvd: #{line}"

            response = line.upcase

            @logger.info "CapitalServer: sending: #{response}"

            client.puts(response)
          end
        end

        client.close
      end

    end
  end

  def keyboard_sizes
    [
      { name: 'Redox', size: '60%'},
      { name: 'Cornelius', size: '40%'},
      { name: '<italic>', size: '55%' }
    ]
  end

  def parse_request(request_line, socket)
    method, target, version = request_line.split(/\s/)

    headers = {}
    loop do
      line = socket.readline.chomp
      break if line.empty?
      header, _match , value = line.partition(':')
      headers[header] = value.strip
    end

    { method: method, target: target, version: version, headers: headers}
  end
  
  def http?(line)
    line.include?("HTTP/1.1")
  end

  def stop
    @thread.kill
    @server.close
  end
end

