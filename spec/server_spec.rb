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

  it 'parses a http request' do
    request = "GET /index.html HTTP/1.1\r\n"

    socket = TCPSocket.new('localhost', 1234)
    socket.puts(request)
    
    request_line = socket.gets.chomp

    expect(request_line).to eq(
      {method: 'GET', target: '/index.html', version: 'HTTP/1.1'}.to_s
    )
  end

  after do
    @server.stop
  end
end
