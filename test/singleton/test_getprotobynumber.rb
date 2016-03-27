########################################################################
# test_getprotobynumber.rb
#
# Test suite for the WSASocket.getprotobynumber method.
########################################################################
require 'test-unit'
require 'win32/socket'

class WSASocketGetprotobynumber < Test::Unit::TestCase
  include Win32

  test "numberpace_providers basic functionality" do
    assert_respond_to(WSASocket, :getprotobynumber)
  end

  test "getprotobynumber requires a numeric argument" do
    assert_raise(ArgumentError){ WSASocket.getprotobynumber }
    assert_nothing_raised{ WSASocket.getprotobynumber(6) }
  end

  test "getprotobynumber returns an integer by default" do
    assert_equal('tcp', WSASocket.getprotobynumber(6))
  end

  test "getprotobynumber returns an array of Protent struct in verbose mode" do
    assert_kind_of(WSASocket::Protoent, WSASocket.getprotobynumber(6, true))
  end
end
