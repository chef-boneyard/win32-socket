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
        @protocol_info = set_protocol_struct(args.delete(:protocol_info))
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

    def self.create(opts = {})
      socket = WSASocketA(
        opts[:address_family],
        opts[:socket_type],
        opts[:protocol],
        opts[:protocol_info],
        opts[:group],
        opts[:flags]
      )

      if socket == INVALID_SOCKET_VALUE
        raise SystemCallError.new('WSASocket', WSAGetLastError())
      end

      socket
    end

    # TODO: Support condition proc
    def accept(condition = nil)
      addr = SockaddrIn.new

      socket = WSAAccept(@socket, addr, addr.size, nil, nil)

      if socket == INVALID_SOCKET_VALUE
        raise SystemCallError.new('WSAAccept', WSAGetLastError())
      end

      socket
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

    # Returns an array of namespace providers by default. If the +verbose+
    # argument is true, it returns an array of WSANAMESPACE_INFO structs that
    # contain additional information.
    #
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

    # Returns an array of supported protocols by default. If the +verbose+
    # option is true, returns an array of WSAPROTOCOL_INFO structs instead,
    # which contain additional information.
    #
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

    # Returns the protocol number for the given +name+.
    #
    def self.getprotobyname(name)
      struct = Protoent.new(GetProtoByName(name))
      [
        struct[:p_name],
        struct[:p_aliases].read_array_of_string,
        struct[:p_proto]
      ]
    end

    # Get the protocol number by name asynchronously. Using this approach you
    # must provide your own FFI buffer and cast it to a Protoent struct on your
    # own once the operation is complete and the buffer has been set.
    #
    # If the +window+ argument (an HWND) is provided, then the +message+ is passed
    # asynchronously to that window once the operation is complete.
    #
    # Returns a HANDLE that is the asynchronous task handle for the request.
    #
    # Example:
    #
    #   require 'win32/wsasocket'
    #   include Windows::WSASocketStructs
    #
    #   buffer = FFI::MemoryPointer.new(:char, 1024)
    #   handle = WSASocket.async_getprotobyname('tcp', buffer, SOME_HWND, SOME_MSG)
    #   # Time passes...
    #   p Protoent.new(buffer)[:p_proto]
    #
    def self.async_getprotobyname(name, buffer, window = 0, message = 0)
      handle = WSAAsyncGetProtoByName(window, message, name, buffer, buffer.size)

      if handle == 0
        raise SystemCallError.new('WSAAsyncGetProtoByName', WSAGetLastError())
      end

      handle
    end

    # Returns the protocol name for the given number.
    #
    def self.getprotobynumber(num)
      struct = Protoent.new(GetProtoByNumber(num))
      [
        struct[:p_name],
        struct[:p_aliases].read_array_of_string,
        struct[:p_proto]
      ]
    end

    # Get the protocol name by number asynchronously. Using this approach you
    # must provide your own FFI buffer and cast it to a Protoent struct on your
    # own once the operation is complete and the buffer has been set.
    #
    # If the +window+ argument (an HWND) is provided, then the +message+ is passed
    # asynchronously to that window once the operation is complete.
    #
    # Returns a HANDLE that is the asynchronous task handle for the request.
    #
    # Example:
    #
    #   require 'win32/wsasocket'
    #   include Windows::WSASocketStructs
    #
    #   buffer = FFI::MemoryPointer.new(:char, 1024)
    #   handle = WSASocket.async_getprotobynumber(6, buffer, SOME_HWND, SOME_MSG)
    #   # Time passes...
    #   p Protoent.new(buffer)[:p_name]
    #
    def self.async_getprotobynumber(number, buffer, window = 0, message = 0)
      handle = WSAAsyncGetProtoByNumber(window, message, number, buffer, buffer.size)

      if handle == 0
        raise SystemCallError.new('WSAAsyncGetProtoByNumber', WSAGetLastError())
      end

      handle
    end

    def self.gethostbyname(name)
      struct = Hostent.new(GetHostByName(name))

      [
        struct[:h_name],
        struct[:h_aliases].read_array_of_string,
        struct[:h_addrtype],
        struct[:h_addr_list].read_array_of_string,
      ]
    end

    #  buffer = FFI::MemoryPointer.new(:char, MAXGETHOSTSTRUCT)
    def self.async_gethostbyname(name, buffer = nil, window = 0, message = 0)
      size_ptr = FFI::MemoryPointer.new(:int)
      size_ptr.write_int(buffer.size)

      handle = WSAAsyncGetHostByName(window, message, name, buffer, size_ptr)

      if handle == 0
        raise SystemCallError.new('WSAAsyncGetHostByName', WSAGetLastError())
      end

      handle
    end

    #  buffer = FFI::MemoryPointer.new(:char, MAXGETHOSTSTRUCT)
    def self.async_gethostbyaddr(addr, addr_type, buffer, window = 0, message = 0)
      handle = WSAAsyncGetHostByAddr(window, message, addr, addr.size, addr_type, buffer, buffer.size)

      if handle == 0
        raise SystemCallError.new('WSAAsyncGetHostByAddr', WSAGetLastError())
      end

      handle
    end

    #  buffer = FFI::MemoryPointer.new(:char, MAXGETHOSTSTRUCT)
    def self.async_getservbyport(port, proto, buffer, window = 0, message = 0)
      handle = WSAAsyncGetServByPort(window, message, port, proto, buffer, buffer.size)

      if handle == 0
        raise SystemCallError.new('WSAAsyncGetServByPort', WSAGetLastError())
      end

      handle
    end

    def self.getaddrinfo(host, service = nil, hints = {})
      res = FFI::MemoryPointer.new(Addrinfo)

      if hints.empty?
        hint = nil
      else
        hint = Addrinfo.new
        hint[:ai_flags] = hints.delete(:flags) || 0
        hint[:ai_family] = hints.delete(:family) || 0
        hint[:ai_protocol] = hints.delete(:protocol) || 0
        hint[:ai_socktype] = hints.delete(:socktype) || 0

        raise ArgumentError, "Unsupported hint(s): " + hints.keys.join(', ') unless hints.empty?
      end

      if GetAddrInfo(host, service, hint, res) != 0
        raise SystemCallError.new('getaddrinfo', FFI.errno)
      end

      addr = Addrinfo.new(res.read_pointer)
      array = []

      loop do
        array << addr
        break if addr[:ai_next].null?
        addr = Addrinfo.new(addr[:ai_next])
      end

      array
    end

    private

    def set_protocol_struct(opts)
      protocol_info = WSAPROTOCOL_INFO.new

      opts.each{ |k,v|
        protocol_info[:dwServiceFlags1] = k[:service_flags]
        protocol_info[:dwProviderFlags] = k[:provider_flags]
        protocol_info[:ProviderId] = k[:provider_id]
        protocol_info[:dwCatalogEntryId] = k[:catalog_entry_id]
        protocol_info[:ProtocolChain] = k[:protocol_chain]
        protocol_info[:iVersion] = k[:version]
        protocol_info[:iAddressFamily] = k[:address_family]
        protocol_info[:iMaxSockAddr] = k[:maximum_address_length]
        protocol_info[:iMinSockAddr] = k[:minimum_address_length]
        protocol_info[:iSocketType] = k[:socket_type]

        if k[:protocol]
          if k[:protocol].is_a?(String)
            protocol_info[:szProtocol] = k[:protocol]
          else
            protocol_info[:iProtocol] = k[:protocol]
          end
        end

        protocol_info[:iProtocolMaxOffset] = k[:protocol_maximum_offset]
        protocol_info[:iNetworkByteOrder] = k[:network_byte_order]
        protocol_info[:iSecurityScheme] = k[:security_scheme]
        protocol_info[:dwMessageSize] = k[:message_size]
      }

      protocol_info
    end

  end # WSASocket
end # Win32

if $0 == __FILE__
  include Win32

  #s = WSASocket.new(:address_family => WSASocket::AF_INET)
  #s.connect('www.google.com')
  #s.close

  p WSASocket.getprotobyname('tcp')
  p WSASocket.getprotobynumber(6)
end
