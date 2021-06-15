require 'spec_helper'
require 'capital_server'
require 'socket'
require 'net/http'

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
      skip "we're not reading the bod yet"
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
      response = Net::HTTP.get(URI('http://localhost:1234'))

      expect(response).to eq("method: GET, target: /, version: HTTP/1.1")
    end
  end

  context "responding with HTML" do
    it "responds to the show-data path as html" do
      response = Net::HTTP.get_response(URI('http://localhost:1234/show-data'))

      expect(response['Content-Type']).to eq('text/html')
      expect(response).to be_a(Net::HTTPSuccess)
    end

    it "responds with a list of html escaped keyboard types" do
      response = Net::HTTP.get(URI('http://localhost:1234/show-data'))

      expect(response).to eq(<<~HTML.chomp)
      <ul>
      <li>Redox <strong>60%</strong></li>
      <li>Cornelius <strong>40%</strong></li>
      <li>&lt;italic&gt; <strong>55%</strong></li>
      </ul>
      HTML
    end
  end

  after do
    @server.stop
  end
end

