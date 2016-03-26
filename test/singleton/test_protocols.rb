########################################################################
# test_protocols.rb
#
# Test suite for the WSASocket.protocols method.
########################################################################
require 'test-unit'
require 'win32/socket'

class WSASocketProtocols < Test::Unit::TestCase
  include Win32

  test "namepace_providers basic functionality" do
    assert_respond_to(WSASocket, :protocols)
  end

  test "protocols accepts an optional boolean argument" do
    assert_nothing_raised{ WSASocket.protocols }
    assert_nothing_raised{ WSASocket.protocols(true) }
    assert_nothing_raised{ WSASocket.protocols(false) }
  end

  test "protocols returns an array of strings by default" do
    assert_kind_of(Array, WSASocket.protocols)
    assert_kind_of(String, WSASocket.protocols.first)
  end

  test "protocols returns an array of WSANAMESPACE_INFO structs in verbose mode" do
    assert_kind_of(Array, WSASocket.protocols(true))
    assert_kind_of(WSASocket::WSAPROTOCOL_INFO, WSASocket.protocols(true).first)
  end

  test "protocols returns some expected values" do
    assert_true(WSASocket.protocols.include?('MSAFD Tcpip [TCP/IP]'))
    assert_true(WSASocket.protocols.include?('MSAFD Tcpip [UDP/IP]'))
  end
end
