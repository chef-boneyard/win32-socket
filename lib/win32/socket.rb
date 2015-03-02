require_relative 'socket/constants'
require_relative 'socket/structs'
require_relative 'socket/functions'
require_relative 'socket/helper'

module Win32
  class WSASocket
    include Windows::WSASocketConstants
    include Windows::WSASocketStructs
    include Windows::WSASocketFunctions

    attr_reader :address_family
    attr_reader :socket_type
    attr_reader :protocol
    attr_reader :group
    attr_reader :flags

    # Example:
    #
    # socket = WSASocket.new(
    #   :address_family => WSASocket::AF_INET,
    #   :socket_type    => WSASocket::SOCK_STREAM,
    #   :protocol       => WSASocket::IPPROTO_TCP
    # )
    def initialize(args = {})
      @address_family = args.delete(:address_family) || AF_INET
      @socket_type = args.delete(:socket_type) || SOCK_STREAM
      @protocol = args.delete(:protocol) || IPPROTO_TCP
      @group = args.delete(:group) || 0
      @flags = args.delete(:flags) || WSA_FLAG_OVERLAPPED

      # Pass remaining members to WSAPROTOCOL_INFO

      @socket = WSASocketA(@address_family, @socket_type, @protocol, nil, @group, @flags)

      if @socket == INVALID_SOCKET_VALUE
        raise SystemCallError.new('WSASocket', WSAGetLastError())
      end
    end

    def close
      if closesocket(@socket) == SOCKET_ERROR
        raise SystemCallError.new("closesocket", WSAGetLastError())
      end
    end
  end
end

if $0 == __FILE__
  include Win32
  s = WSASocket.new
  p s
  s.close
end
