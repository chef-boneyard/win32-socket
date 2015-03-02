require 'ffi'
require_relative 'socket/constants'
require_relative 'socket/structs'
require_relative 'socket/functions'
require_relative 'socket/helper'

module Win32
  class WSASocket
    extend FFI::Library
    ffi_lib :ws2_32

    include Windows::WSASocketConstants

    attr_reader :address_family
    attr_reader :socket_type
    attr_reader :protocol

    # Example:
    #
    # socket = WSASocket.new(
    #   :address_family => WSASocket::AF_INET,
    #   :socket_type    => WSASocket::SOCK_STREAM,
    #   :protocol       => WSASocket::IPPROTO_TCP
    # )
    def initialize(args = {})
      @address_family = args[:address_family] || AF_INET
      @socket_type = args[:socket_type] || SOCK_STREAM
      @protocol = args[:protocol] || IPPROTO_TCP
    end
  end
end

if $0 == __FILE__
  include Win32
  s = WSASocket.new
  p s
end
