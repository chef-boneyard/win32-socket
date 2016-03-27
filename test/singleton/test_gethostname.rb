########################################################################
# test_gethostname.rb
#
# Test suite for the WSASocket.gethostname method.
########################################################################
require 'test-unit'
require 'win32/socket'

class WSASocketGethostname < Test::Unit::TestCase
  include Win32

  test "gethostname basic functionality" do
    assert_respond_to(WSASocket, :gethostname)
    assert_kind_of(String, WSASocket.gethostname)
  end

  test "gethostname returns the expected result" do
    assert_equal(`hostname`.chomp, WSASocket.gethostname)
  end

  test "gethostname does not accept any arguments" do
    assert_raise(ArgumentError){ WSASocket.gethostname(true) }
  end
end
