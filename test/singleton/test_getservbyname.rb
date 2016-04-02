########################################################################
# test_getservbyname.rb
#
# Test suite for the WSASocket.getservbyname method.
########################################################################
require 'test-unit'
require 'win32/socket'

class WSASocketGetservbyname < Test::Unit::TestCase
  include Win32

  test "getservbyname basic functionality" do
    assert_respond_to(WSASocket, :getservbyname)
    assert_nothing_raised{ WSASocket.getservbyname('http') }
  end

  test "getservbyname returns an integer in regular mode" do
    assert_kind_of(Integer, WSASocket.getservbyname('http'))
  end

  test "getservbyname accepts an optional protocol type" do
    assert_nothing_raised{ WSASocket.getservbyname('http', 'tcp') }
  end

  test "getservbyname returns a struct in verbose mode" do
    assert_kind_of(Struct::Servent, WSASocket.getservbyname('http', nil, true))
    assert_kind_of(Struct::Servent, WSASocket.getservbyname('http', 'tcp', true))
  end

  test "getservbyname struct members return expected values" do
    struct = WSASocket.getservbyname('http', nil, true)
    assert_kind_of(String, struct.name)
    assert_kind_of(Array, struct.aliases)
    assert_kind_of(Numeric, struct.port)
    assert_kind_of(String, struct.proto)
  end

  test "getservname requires a string argument" do
    assert_raise(ArgumentError){ WSASocket.getservbyname }
  end
end
