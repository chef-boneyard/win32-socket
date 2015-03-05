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
    attr_reader :protocol_info
    attr_reader :group
    attr_reader :flags
    attr_reader :port
    attr_reader :address

    # Example:
    #
    # socket = WSASocket.new(
    #   :address        => '127.0.0.1',
    #   :port           => 3301,
    #   :address_family => WSASocket::AF_INET,
    #   :socket_type    => WSASocket::SOCK_STREAM,
    #   :protocol       => WSASocket::IPPROTO_TCP,
    #   :group          => WSASocket::SG_UNCONSTRAINED_GROUP,
    #   :flags          => WSASocket::WSA_FLAG_OVERLAPPED | WSASocket::WSA_NO_HANDLE_INHERIT
    # )
    def initialize(args = {})
      @address_family = args.delete(:address_family) || AF_INET
      @socket_type    = args.delete(:socket_type)    || SOCK_STREAM
      @protocol       = args.delete(:protocol)       || IPPROTO_TCP
      @group          = args.delete(:group)          || 0
      @flags          = args.delete(:flags)          || WSA_FLAG_OVERLAPPED
      @port           = args.delete(:port)
      @address        = args.delete(:address)

      if args[:protocol_info]
        @protocol_info = WSAPROTOCOL_INFO.new
        args.delete(:protocol_info).each{ |k,v| @protocol_info.send(k, v) }
      end

      if args.keys.size > 0
        raise ArgumentError, "invalid key(s): #{args.keys.join(', ')}"
      end

      @socket = WSASocketA(
        @address_family,
        @socket_type,
        @protocol,
        @protocol_info,
        @group,
        @flags
      )

      if @socket == INVALID_SOCKET_VALUE
        raise SystemCallError.new('WSASocket', WSAGetLastError())
      end
    end

    def connect
    end

    def close
      if closesocket(@socket) == SOCKET_ERROR
        raise SystemCallError.new("closesocket", WSAGetLastError())
      end

      if WSACleanup() == SOCKET_ERROR
        raise SystemCallError.new("WSACleanup", WSAGetLastError())
      end
    end
  end
end

if $0 == __FILE__
  include Win32
  s = WSASocket.new(:address_family => WSASocket::AF_INET)
  p s
  s.close
end
