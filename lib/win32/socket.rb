require_relative 'socket/constants'
require_relative 'socket/structs'
require_relative 'socket/functions'
require_relative 'socket/helper'

module Win32
  class WSASocket
    include Windows::WSASocketConstants
    include Windows::WSASocketStructs
    include Windows::WSASocketFunctions
    extend Windows::WSASocketStructs
    extend Windows::WSASocketFunctions

    attr_reader :address_family
    attr_reader :socket_type
    attr_reader :protocol
    attr_reader :protocol_info
    attr_reader :group
    attr_reader :flags
    attr_reader :port
    attr_reader :address

    # Creates and returns a new Win32::Socket instance. The following +args+ are
    # possible:
    #
    # :address_family - Default is AF_INET.
    # :socket_type    - Default is SOCK_STREAM.
    # :protocol       - Default protocol is IPPROTO_TCP.
    # :group          - No socket group by default.
    # :flags          - Default is WSA_FLAG_OVERLAPPED.
    # :socket         - Create a new socket from an existing FD.
    #
    # You can also specify the :protocol_info option which is a hash that may
    # contain any of the following keys:
    #
    #   :service_flags
    #   :provider_flags
    #   :provider_id
    #   :catalog_entry_id
    #   :protocol_chain
    #   :version
    #   :address_family
    #   :maximum_address_length
    #   :minimum_address_length
    #   :socket_type
    #   :protocol
    #   :protocol_maximum_offset
    #   :network_byte_order
    #   :security_scheme
    #   :message_size
    #
    # Example:
    #
    # socket = WSASocket.new(
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

      # Typically passed when creating a new object from an existing FD.
      @socket         = args.delete(:socket)
      @port           = args.delete(:port)
      @address        = args.delete(:address)

      @protocol_info = nil

      if args[:protocol_info]
        @protocol_info = WSAPROTOCOL_INFO.new
        args.delete(:protocol_info).each{ |k,v|
          @protocol_info[:dwServiceFlags1] = k[:service_flags]
          @protocol_info[:dwProviderFlags] = k[:provider_flags]
          @protocol_info[:ProviderId] = k[:provider_id]
          @protocol_info[:dwCatalogEntryId] = k[:catalog_entry_id]
          @protocol_info[:ProtocolChain] = k[:protocol_chain]
          @protocol_info[:iVersion] = k[:version]
          @protocol_info[:iAddressFamily] = k[:address_family]
          @protocol_info[:iMaxSockAddr] = k[:maximum_address_length]
          @protocol_info[:iMinSockAddr] = k[:minimum_address_length]
          @protocol_info[:iSocketType] = k[:socket_type]

          if k[:protocol].is_a?(String)
            @protocol_info[:szProtocol] = k[:protocol]
          else
            @protocol_info[:iProtocol] = k[:protocol]
          end

          @protocol_info[:iProtocolMaxOffset] = k[:protocol_maximum_offset]
          @protocol_info[:iNetworkByteOrder] = k[:network_byte_order]
          @protocol_info[:iSecurityScheme] = k[:security_scheme]
          @protocol_info[:dwMessageSize] = k[:message_size]
        }
      end

      if args.keys.size > 0
        raise ArgumentError, "invalid key(s): #{args.keys.join(', ')}"
      end

      if @socket.nil?
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
    end
    
    # TODO: Support condition proc
    def accept(condition = nil)
      addr = SockaddrIn.new

      socket = WSAAccept(@socket, addr, addr.size, nil, nil)
      
      if socket == INVALID_SOCKET_VALUE
        raise SystemCallError.new('WSASocket', WSAGetLastError())
      end
      
      Socket.new(
        :socket         => socket,
        :address_family => addr[:sin_family],
        :port           => addr[:sin_port],
        :address        => addr[:sin_addr]
      )
    end

    def connect(host, port = 'http', timeout = nil)
      if timeout
        timeval = Timeval.new
        timeval[:tv_sec] = timeout
      else
        timeval = nil
      end

      bool = WSAConnectByNameA(@socket, host, port, nil, nil, nil, nil, timeval, nil)

      unless bool
        raise SystemCallError.new('WSAConnectByName', WSAGetLastError())
      end

      @socket
    end

    def close
      if closesocket(@socket) == SOCKET_ERROR
        raise SystemCallError.new("closesocket", WSAGetLastError())
      end
    end

    def cleanup
      close
      if WSACleanup() == SOCKET_ERROR
        raise SystemCallError.new("WSACleanup", WSAGetLastError())
      end
    end

    # Singleton methods

    def self.namespace_providers(verbose = false)
      buflen = FFI::MemoryPointer.new(:ulong)
      buffer = FFI::MemoryPointer.new(WSANAMESPACE_INFO, 128)

      buflen.write_int(buffer.size)

      int = WSAEnumNameSpaceProvidersA(buflen, buffer)

      if int == SOCKET_ERROR
        raise SystemCallError.new('WSAEnumNameSpaceProviders', WSAGetLastError())
      end

      arr = []

      int.times{
        info = WSANAMESPACE_INFO.new(buffer)
        if verbose
          arr << info
        else
          arr << info[:lpszIdentifier]
        end
        buffer += WSANAMESPACE_INFO.size
      }

      arr
    end

    def self.protocols(verbose = false)
      buflen = FFI::MemoryPointer.new(:ulong)
      buffer = FFI::MemoryPointer.new(WSAPROTOCOL_INFO, 128)

      buflen.write_int(buffer.size)

      int = WSAEnumProtocolsA(nil, buffer, buflen)

      if int == SOCKET_ERROR
        raise SystemCallError.new('WSAEnumProtocols', WSAGetLastError())
      end

      arr = []

      int.times{
        info = WSAPROTOCOL_INFO.new(buffer)
        if verbose
          arr << info
        else
          arr << info[:szProtocol].to_s
        end
        buffer += WSAPROTOCOL_INFO.size
      }

      arr
    end

    def self.getprotobyname(name)
      buffer = FFI::MemoryPointer.new(:char, MAXGETHOSTSTRUCT)
      size_ptr = FFI::MemoryPointer.new(:int)
      size_ptr.write_int(buffer.size)

      handle = WSAAsyncGetProtoByName(0, 0, name, buffer, size_ptr)

      if handle == 0
        raise SystemCallError.new('WSAAsyncGetProtoByName', WSAGetLastError())
      end

      struct = Protoent.new(buffer)
      SleepEx(1, true) while struct[:p_proto].nil?
      struct[:p_proto]
    end

    def self.getprotobynumber(number)
      buffer = FFI::MemoryPointer.new(:char, MAXGETHOSTSTRUCT)
      size_ptr = FFI::MemoryPointer.new(:int)
      size_ptr.write_int(buffer.size)

      handle = WSAAsyncGetProtoByNumber(0, 0, number, buffer, size_ptr)

      if handle == 0
        raise SystemCallError.new('WSAAsyncGetProtoByNumber', WSAGetLastError())
      end

      struct = Protoent.new(buffer)
      SleepEx(1, true) while struct[:p_name].nil?
      struct[:p_name]
    end

    def self.gethostbyname(name)
      buffer = FFI::MemoryPointer.new(:char, MAXGETHOSTSTRUCT)
      size_ptr = FFI::MemoryPointer.new(:int)
      size_ptr.write_int(buffer.size)

      handle = WSAAsyncGetHostByName(0, 0, name, buffer, size_ptr)

      if handle == 0
        raise SystemCallError.new('WSAAsyncGetHostByName', WSAGetLastError())
      end

      struct = Hostent.new(buffer)
      SleepEx(5, true) while struct[:h_addr_list].address == 0
      struct[:h_addr_list].read_array_of_string
    end

    def self.gethostbyaddr(addr, addr_type = AF_INET)
      buffer = FFI::MemoryPointer.new(:char, MAXGETHOSTSTRUCT)

      handle = WSAAsyncGetHostByAddr(0, 0, addr, addr.size, addr_type, buffer, buffer.size)

      if handle == 0
        raise SystemCallError.new('WSAAsyncGetHostByAddr', WSAGetLastError())
      end

      struct = Hostent.new(buffer)
      SleepEx(10, true) while struct[:h_name].nil?
      struct[:h_name]
    end

  end # WSASocket
end # Win32

if $0 == __FILE__
  include Win32
  #s = WSASocket.new(:address_family => WSASocket::AF_INET)
  #s.connect('www.google.com')
  #s.close

  p WSASocket.gethostbyaddr('216.58.217.46')
end
