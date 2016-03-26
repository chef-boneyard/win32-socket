########################################################################
# test_namespace_providers.rb
#
# Test suite for the WSASocket.namespace_providers method.
########################################################################
require 'test-unit'
require 'win32/socket'

class WSASocketNamespaceProviders < Test::Unit::TestCase
  include Win32

  test "namepace_providers basic functionality" do
    assert_respond_to(WSASocket, :namespace_providers)
  end

  test "namespace_providers accepts an optional boolean argument" do
    assert_nothing_raised{ WSASocket.namespace_providers }
    assert_nothing_raised{ WSASocket.namespace_providers(true) }
    assert_nothing_raised{ WSASocket.namespace_providers(false) }
  end

  test "namespace_providers returns an array of strings by default" do
    assert_kind_of(Array, WSASocket.namespace_providers)
    assert_kind_of(String, WSASocket.namespace_providers.first)
  end

  test "namespace_providers returns an array of WSANAMESPACE_INFO structs in verbose mode" do
    assert_kind_of(Array, WSASocket.namespace_providers(true))
    assert_kind_of(WSASocket::WSANAMESPACE_INFO, WSASocket.namespace_providers(true).first)
  end

  test "namespace_providers returns some expected values" do
    assert_true(WSASocket.namespace_providers.include?('Tcpip'))
    assert_true(WSASocket.namespace_providers.include?('NTDS'))
  end
end
