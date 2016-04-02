########################################################################
# test_getservbyport.rb
#
# Test suite for the WSASocket.getservbyport method.
########################################################################
require 'test-unit'
require 'win32/socket'

class WSASocketGetservbyport < Test::Unit::TestCase
  include Win32

  test "getservbyport basic functionality" do
    assert_respond_to(WSASocket, :getservbyport)
    assert_nothing_raised{ WSASocket.getservbyport(80) }
  end

  test "getservbyport returns a string in regular mode" do
    assert_kind_of(String, WSASocket.getservbyport(80))
  end

  test "getservbyport accepts an optional protocol type" do
    assert_nothing_raised{ WSASocket.getservbyport(80, 'tcp') }
  end

  test "getservbyport returns a struct in verbose mode" do
    assert_kind_of(Struct::Servent, WSASocket.getservbyport(80, nil, true))
    assert_kind_of(Struct::Servent, WSASocket.getservbyport(80, 'tcp', true))
  end

  test "getservbyport struct members return expected values" do
    struct = WSASocket.getservbyport(80, nil, true)
    assert_kind_of(String, struct.name)
    assert_kind_of(Array, struct.aliases)
    assert_kind_of(Numeric, struct.port)
    assert_kind_of(String, struct.proto)
  end

  test "getservport requires a string argument" do
    assert_raise(ArgumentError){ WSASocket.getservbyport }
  end
end
