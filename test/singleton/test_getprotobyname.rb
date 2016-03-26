########################################################################
# test_getprotobyname.rb
#
# Test suite for the WSASocket.getprotobyname method.
########################################################################
require 'test-unit'
require 'win32/socket'

class WSASocketGetprotobyname < Test::Unit::TestCase
  include Win32

  test "namepace_providers basic functionality" do
    assert_respond_to(WSASocket, :getprotobyname)
  end

  test "getprotobyname requires a string argument" do
    assert_raise(ArgumentError){ WSASocket.getprotobyname }
    assert_nothing_raised{ WSASocket.getprotobyname('TCP') }
  end

  test "getprotobyname returns an integer by default" do
    assert_equal(6, WSASocket.getprotobyname('TCP'))
  end

  test "getprotobyname returns an array of Protent struct in verbose mode" do
    assert_kind_of(WSASocket::Protoent, WSASocket.getprotobyname('TCP', true))
  end
end
