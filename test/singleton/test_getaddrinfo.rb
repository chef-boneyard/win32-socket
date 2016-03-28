########################################################################
# test_getaddrinfo.rb
#
# Test suite for the WSASocket.getaddrinfo method.
########################################################################
require 'test-unit'
require 'win32/socket'

class WSASocketGetaddrinfo < Test::Unit::TestCase
  include Win32

  def setup
    @hostname = 'www.ruby-lang.org'
    @service  = 'http'
  end

  test "getaddrinfo basic functionality" do
    assert_respond_to(WSASocket, :getaddrinfo)
  end

  test "getaddrinfo returns expected object type" do
    host = `hostname`.chomp
    assert_kind_of(Array, WSASocket.getaddrinfo(host))
    assert_kind_of(Struct::AddrInfo, WSASocket.getaddrinfo(host).first)
  end

  test "getaddrinfo accepts an optional service type" do
    assert_nothing_raised{ WSASocket.getaddrinfo(@hostname, @service) }
  end

  test "getaddrinfo accepts optional flags" do
    assert_nothing_raised{ WSASocket.getaddrinfo(@hostname, @service, :flags => WSASocket::AI_CANONNAME) }
  end

  test "the ip_address flag is set to an expected value" do
    array = WSASocket.getaddrinfo(@hostname, @service, :flags => WSASocket::AI_CANONNAME)
    assert_kind_of(String, array.first.ip_address)
    assert_true(array.first.ip_address.size >= 7)
  end

  test "the canonical_name is set if AI_CANONNAME is specified as a flag" do
    array = WSASocket.getaddrinfo(@hostname, @service, :flags => WSASocket::AI_CANONNAME)
    assert_kind_of(String, array.first.canonical_name)
  end

  test "getaddrinfo requires at least one argument" do
    assert_raise(ArgumentError){ WSASocket.getaddrinfo }
  end

  test "getaddrinfo raises an error if an invalid service name is provided" do
    assert_raise(SystemCallError){ WSASocket.getaddrinfo(@hostname, 'bogus') }
  end

  def teardown
    @service  = nil
    @hostname = nil
  end
end
