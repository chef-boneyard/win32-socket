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
end
