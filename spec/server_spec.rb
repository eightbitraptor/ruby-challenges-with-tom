require 'spec_helper'
require 'capital_server'
require 'socket'

RSpec.describe "a capitalisation server" do
  before do
    @server = CapitalServer.new(1234)
    @server.start
  end

  it 'capitalises data sent to the server' do
    socket = TCPSocket.new('localhost', 1234)

    socket.puts('hello')
    line = socket.gets.chomp
    socket.close

    expect(line).to eq("HELLO")
  end

  it 'upcases multiple lines' do
    socket = TCPSocket.new('localhost', 1234) 

    ['hello', 'there', 'Tom'].each do |token|
      $stderr.puts "pushing token: #{token}"
      socket.puts token
      line = socket.gets.chomp

      expect(line).to eq(token.upcase)
    end

    socket.close
  end

  it 'connects with multiple sockets' do
    2.times do
      socket = TCPSocket.new('localhost', 1234)
      socket.puts('hello')
      line = socket.gets.chomp
      socket.close

      expect(line).to eq("HELLO")
    end
  end

  context 'parsing a http request' do
    let(:request) {
      [
        "GET /index.html HTTP/1.1\r\n",
        "User-Agent: myrubytests\r\n",
        "Accept: *\r\n",
        "\r\n",
        "this is the body\r\n",
        "it has more than one line\r\n",
      ].join
    }

    it 'parses the request line' do
      queue = Queue.new

      @server.on_request { |request|
        queue.push(request)
      }

      socket = TCPSocket.new('localhost', 1234)
      socket.puts(request)
      # idk if i have to explicitly close the socket here?
      socket.close

      expect(queue.pop).to include(
        method: 'GET', target: '/index.html', version: 'HTTP/1.1'
      )
    end

    it 'parses the headers' do
      queue = Queue.new

      @server.on_request { |request|
        queue.push(request)
      }

      socket = TCPSocket.new('localhost', 1234)
      socket.puts(request)
      # idk if i have to explicitly close the socket here?
      socket.close

      expect(queue.pop).to include(
        headers: {'Accept' => '*', 'User-Agent' => 'myrubytests'}
      )
    end

    it 'parses the body' do
      skip
      queue = Queue.new

      @server.on_request { |request|
        queue.push(request)
      }

      socket = TCPSocket.new('localhost', 1234)
      socket.puts(request)
      # idk if i have to explicitly close the socket here?
      socket.close

      expect(queue.pop).to include(
        # escaped crlf, is this right?
        body: "this is the body\r\nit has more than one line"
      )
    end
  end

  context "reading a HTTP response" do
    it "does stuff" do
      require 'net/http'

      response = Net::HTTP.get(URI('http://localhost:1234'))

      expect(response).to eq("method: GET, target: /, version: HTTP/1.1")
    end
  end

  after do
    @server.stop
  end
end
