########################################################################
# test_gethostbyname.rb
#
# Test suite for the WSASocket.gethostbyname method.
########################################################################
require 'test-unit'
require 'win32/socket'

class WSASocketGethostbyname < Test::Unit::TestCase
  include Win32

  def self.startup
    @@hostname = `hostname`.chomp
  end

  test "gethostbyname basic functionality" do
    assert_respond_to(WSASocket, :gethostbyname)
    assert_nothing_raised{ WSASocket.gethostbyname(@@hostname) }
  end

  test "gethostbyname returns a struct" do
    assert_kind_of(Struct::Host, WSASocket.gethostbyname(@@hostname))
  end

  test "gethostbyname struct members return expected values" do
    struct = WSASocket.gethostbyname(@@hostname)
    assert_kind_of(String, struct.name)
    assert_kind_of(Array, struct.aliases)
    assert_kind_of(Numeric, struct.addr_type)
    assert_kind_of(Array, struct.addr_list)
  end

  test "gethostname requires a string argument" do
    assert_raise(ArgumentError){ WSASocket.gethostbyname }
  end

  def self.shutdown
    @@hostname = nil
  end
end
