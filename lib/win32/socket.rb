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

    # The socket address family, e.g. AF_INET.
    attr_reader :address_family

    # The socket type, e.g. SOCK_STREAM
    attr_reader :socket_type

    # The socket protocol, e.g. IPPROTO_TCP
    attr_reader :protocol

    # Protocol information. See the constructor for details.
    attr_reader :protocol_info

    # The name of the socket group. May be nil.
    attr_reader :group

    # Integer value of OR'd flags for the socket.
    attr_reader :flags

    # The address of the socket.
    attr_reader :address

    # The local address of a connection.
    attr_reader :local_address

    # The remote address of a connection.
    attr_reader :remote_address

    # Creates and returns a new Win32::Socket instance. The following +args+ are
    # possible:
    #
    # :address_family - Default is AF_INET.
    # :socket_type    - Default is SOCK_STREAM.
    # :protocol       - Default protocol is IPPROTO_TCP.
    # :group          - No socket group by default.
    # :flags          - Default is WSA_FLAG_OVERLAPPED.
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

      # Set in connect call
      @local_address  = nil
      @remote_address = nil

      if args[:protocol_info]
        @protocol_info = set_protocol_struct(args.delete(:protocol_info))
      else
        @protocol_info = nil
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
        FFI.raise_windows_error('WSASocket', WSAGetLastError())
      end

      if block_given?
        begin
          yield self
        ensure
          close
        end
      end

      ObjectSpace.define_finalizer(self, self.class.finalize(@socket))
    end

    def accept(condition = nil)
      addr = SockaddrIn.new

      socket = WSAAccept(@socket, addr, addr.size, nil, nil)

      if socket == INVALID_SOCKET_VALUE
        FFI.raise_windows_error('WSAAccept', WSAGetLastError())
      end

      socket
    end

    def connect(host, service = 'http', timeout = nil)
      if timeout
        timeval = Timeval.new
        timeval[:tv_sec] = timeout
      else
        timeval = nil
      end

      if service.is_a?(Fixnum)
        service = self.class.getservbyport(service)
      end

      local = Sockaddr.new
      local_size = FFI::MemoryPointer.new(:ulong)
      local_size.write_ulong(local.size)

      remote = Sockaddr.new
      remote_size = FFI::MemoryPointer.new(:ulong)
      remote_size.write_ulong(remote.size)

      bool = WSAConnectByNameA(@socket, host, service, local_size, local, remote_size, remote, timeval, nil)

      unless bool
        FFI.raise_windows_error('WSAConnectByName', WSAGetLastError())
      end

      @local_address  = SockaddrStruct.new(local[:sa_family], local[:sa_data].to_s)
      @remote_address = SockaddrStruct.new(remote[:sa_family], remote[:sa_data].to_s)

      @socket
    end

    def close
      if closesocket(@socket) == SOCKET_ERROR
        FFI.raise_windows_error('closesocket', WSAGetLastError())
      end

      @local_address  = nil
      @remote_address = nil

      true
    end

    def cleanup
      close
      if WSACleanup() == SOCKET_ERROR
        FFI.raise_windows_error('WSACleanup', WSAGetLastError())
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
        FFI.raise_windows_error('WSAEnumNameSpaceProviders', WSAGetLastError())
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
        FFI.raise_windows_error('WSAEnumProtocols', WSAGetLastError())
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

    # Returns the protocol number for the given +name+. If +verbose+ is true,
    # then a Protoent struct is returned instead, which contains the following
    # members:
    #
    # * p_name
    # * p_aliases
    # * p_proto
    #
    def self.getprotobyname(name, verbose = false)
      struct = Protoent.new(GetProtoByName(name))

      if verbose
        ProtoentStruct.new(
          struct[:p_name],
          struct[:p_aliases].read_array_of_string,
          struct[:p_proto]
        )
      else
        struct[:p_proto]
      end
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
        FFI.raise_windows_error('WSAAsyncGetProtoByName', WSAGetLastError())
      end

      handle
    end

    # Returns the protocol name for the given +number+. If +verbose+ is true,
    # then a Protoent struct is returned instead, which contains the following
    # members:
    #
    # * p_name
    # * p_aliases
    # * p_proto
    #
    def self.getprotobynumber(num, verbose = false)
      struct = Protoent.new(GetProtoByNumber(num))

      if verbose
        ProtoentStruct.new(
          struct[:p_name],
          struct[:p_aliases].read_array_of_string,
          struct[:p_proto]
        )
      else
        struct[:p_name]
      end
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
        FFI.raise_windows_error('WSAAsyncGetProtoByNumber', WSAGetLastError())
      end

      handle
    end

    # Return the standard host for the local computer. On Windows 8 or later
    # this will return a UTF-16LE encoding string.
    #--
    # Windows 8+ uses the GetHostNameW function internally.
    #
    def self.gethostname
      buffer = 0.chr * 256

      if respond_to?(:GetHostNameW)
        buffer.encode!(Encoding::UTF_16LE)
        if GetHostNameW(buffer, buffer.size) != 0
          FFI.raise_windows_error('GetHostNameW', FFI.errno)
        end
      else
        if GetHostName(buffer, buffer.size) != 0
          FFI.raise_windows_error('gethostname', FFI.errno)
        end
      end

      buffer.strip.encode(Encoding.default_external)
    end

    # Returns a Struct::Host object containing information for the given +name+.
    #
    # Note that the WSASocket.getaddrinfo method is preferred over this.
    #
    def self.gethostbyname(name)
      struct = Hostent.new(GetHostByName(name))

      HostStruct.new(
        struct[:h_name],
        struct[:h_aliases].read_array_of_string,
        struct[:h_addrtype],
        struct[:h_addr_list].read_array_of_string,
      )
    end

    #  buffer = FFI::MemoryPointer.new(:char, MAXGETHOSTSTRUCT)
    def self.async_gethostbyname(name, buffer = nil, window = 0, message = 0)
      handle = WSAAsyncGetHostByName(window, message, name, buffer, buffer.size)

      if handle == 0
        FFI.raise_windows_error('WSAAsyncGetHostByName', WSAGetLastError())
      end

      handle
    end

    #  buffer = FFI::MemoryPointer.new(:char, MAXGETHOSTSTRUCT)
    def self.async_gethostbyaddr(addr, addr_type, buffer, window = 0, message = 0)
      handle = WSAAsyncGetHostByAddr(window, message, addr, addr.size, addr_type, buffer, buffer.size)

      if handle == 0
        FFI.raise_windows_error('WSAAsyncGetHostByAddr', WSAGetLastError())
      end

      handle
    end

    # The getservbyname function retrieves service information corresponding
    # to a service +name+ and an optional +protocol+.
    #
    # If the +verbose+ option is true, then a Struct::Servent struct is
    # returned.
    #
    def self.getservbyname(name, proto = nil, verbose = false)
      struct = Servent.new(GetServByName(name, proto))

      if struct.null?
        FFI.raise_windows_error('getservbyname', FFI.errno)
      end

      if verbose
        ServentStruct.new(
          struct[:s_name].read_string,
          struct[:s_aliases].read_array_of_string,
          struct[:s_port].ntohs,
          struct[:s_proto].read_string
        )
      else
        struct[:s_port].ntohs
      end
    end

    def self.async_getservbyname(name, proto, buffer, window = 0, message = 0)
      handle = WSAAsyncGetServByName(window, message, name, proto, buffer, buffer.size)

      if handle == 0
        FFI.raise_windows_error('WSAAsyncGetServByPort', WSAGetLastError())
      end

      handle
    end

    # The getservbyport function retrieves service information corresponding
    # to a service +port+ and an optional +protocol+.
    #
    # If the +verbose+ option is true, then a Struct::Servent struct is
    # returned.
    #
    def self.getservbyport(port, proto = nil, verbose = false)
      struct = Servent.new(GetServByPort(port.htons, proto))

      if struct.null?
        FFI.raise_windows_error('getservbyport', FFI.errno)
      end

      if verbose
        ServentStruct.new(
          struct[:s_name].read_string,
          struct[:s_aliases].read_array_of_string,
          struct[:s_port].ntohs,
          struct[:s_proto].read_string
        )
      else
        struct[:s_name].read_string
      end
    end

    #  buffer = FFI::MemoryPointer.new(:char, MAXGETHOSTSTRUCT)
    def self.async_getservbyport(port, proto, buffer, window = 0, message = 0)
      handle = WSAAsyncGetServByPort(window, message, port, proto, buffer, buffer.size)

      if handle == 0
        FFI.raise_windows_error('WSAAsyncGetServByPort', WSAGetLastError())
      end

      handle
    end

    # This method provides protocol-independent translation from an ANSI host
    # +name+ to an address. You may also specify a service, and any hints
    # you want passed.
    #
    # The result is an array of Struct::AddrInfo objects.
    #
    # Examples:
    #
    #   WSASocket.getaddrinfo(WSASocket.localhost)
    #   WSASocket.getaddrinfo('www.ruby-lang.org', 'http')
    #   WSASocket.getaddrinfo('www.ruby-lang.org', 'http', :flags => WSASocket::AI_CANONNAME)
    #
    def self.getaddrinfo(host, service = nil, hints = {})
      res = FFI::MemoryPointer.new(Addrinfo)

      if hints.empty?
        hint = nil
      else
        hint = AddrinfoW.new
        hint[:ai_flags] = hints.delete(:flags) || 0
        hint[:ai_family] = hints.delete(:family) || 0
        hint[:ai_protocol] = hints.delete(:protocol) || 0
        hint[:ai_socktype] = hints.delete(:socktype) || 0

        raise ArgumentError, "Unsupported hint(s): " + hints.keys.join(', ') unless hints.empty?
      end

      if host.encoding != Encoding::UTF_16LE
        host = (host + 0.chr).encode(Encoding::UTF_16LE)
      end

      if service and service.encoding != Encoding::UTF_16LE
        service = (service + 0.chr).encode(Encoding::UTF_16LE)
      end

      if GetAddrInfoW(host, service, hint, res) != 0
        FFI.raise_windows_error('GetAddrInfoW', FFI.errno)
      end

      addr = AddrinfoW.new(res.read_pointer)

      array = []
      canon_name = nil

      loop do
        array << addr
        break if addr[:ai_next].null?
        addr = AddrinfoW.new(addr[:ai_next])
      end

      unless array.first[:ai_canonname].null?
        canon_name = array.first[:ai_canonname].read_wide_string(512)
      end

      array.map{ |a|
        if [WSASocket::AF_INET, WSASocket::AF_INET6].include?(a[:ai_family])
          buf = 0.chr * 46

          siz_ptr = FFI::MemoryPointer.new(:uintptr_t)
          siz_ptr.write_ulong(buf.size)

          if WSAAddressToStringA(a[:ai_addr], a[:ai_addrlen], nil, buf, siz_ptr) > 0
            FFI.raise_windows_error('WSAAddressToString', WSAGetLastError())
          end
        end

        AddrInfoStruct.new(
          a[:ai_family],
          a[:ai_socktype],
          a[:ai_protocol],
          canon_name,
          buf.strip
        )
      }
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

    private

    # Automatically close socket when it goes out of scope.
    #
    def self.finalize(socket)
      proc{ closesocket(socket) }
    end

  end # WSASocket
end # Win32

if $0 == __FILE__
  include Win32

  s = WSASocket.new(:address_family => WSASocket::AF_INET)
  s.connect('www.google.com')
  s.close

end
