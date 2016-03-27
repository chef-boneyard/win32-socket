require 'ffi'

module Windows
  module WSASocketStructs
    extend FFI::Library

    typedef :ulong, :dword
    typedef :ushort, :word

    class GUID < FFI::Struct
      layout(:Data1, :dword, :Data2, :word, :Data3, :word, :Data4, [:uchar, 8])
    end

    class Sockaddr < FFI::Struct
      layout(:sa_family, :ushort, :sa_data, [:char, 14])
    end

    class InAddr < FFI::Struct
      layout(:s_addr, :ulong)
    end

    class SockaddrIn < FFI::Struct
      layout(
        :sin_family, :short,
        :sin_port, :ushort,
        :sin_addr, InAddr,
        :sin_zero, [:char, 8]
      )
    end

    sa_family_t = FFI::Type::UINT

    SS_MAXSIZE   = 128
    SS_ALIGNSIZE = FFI::MemoryPointer.new(:int64).size
    SS_PAD1SIZE  = SS_ALIGNSIZE - sa_family_t.size
    SS_PAD2SIZE  = SS_MAXSIZE - (sa_family_t.size + SS_PAD1SIZE + SS_ALIGNSIZE)

    class SockaddrStorage < FFI::Struct
      layout(
        :ss_family, :short,
        :ss_pad1, [:char, SS_PAD1SIZE],
        :ss_align, :int64,
        :ss_pad2, [:char, SS_PAD2SIZE],
      )
    end

    class Timeval < FFI::Struct
      layout(:tv_sec, :long, :tv_usec, :long)
    end

    MAX_PROTOCOL_CHAIN = 7
    WSAPROTOCOL_LENGTH = 256

    class WSAPROTOCOL_CHAIN < FFI::Struct
      layout(:ChainLen, :int, :ChainEntries, [:dword, MAX_PROTOCOL_CHAIN])
    end

    class WSAPROTOCOL_INFO < FFI::Struct
      layout(
        :dwServiceFlags1, :dword,
        :dwServiceFlags2, :dword,
        :dwServiceFlags3, :dword,
        :dwServiceFlags4, :dword,
        :dwProviderFlags, :dword,
        :ProviderID, GUID,
        :dwCatalogEntryId, :dword,
        :ProtocolChain, WSAPROTOCOL_CHAIN,
        :iVersion, :int,
        :iAddressFamily, :int,
        :iMaxSockAddr, :int,
        :iMinSockAddr, :int,
        :iSocketType, :int,
        :iProtocol, :int,
        :iProtocolMaxOffset, :int,
        :iNetworkByteOrder, :int,
        :iSecurityScheme, :int,
        :dwMessageSize, :dword,
        :dwProviderReserved, :dword,
        :szProtocol, [:char, WSAPROTOCOL_LENGTH]
      )
    end

    class WSANAMESPACE_INFO < FFI::Struct
      layout(
        :NSProviderId, GUID,
        :dwNameSpace, :dword,
        :fActive, :bool,
        :dwVersion, :dword,
        :lpszIdentifier, :string
      )
    end

    class Protoent < FFI::Struct
      layout(
        :p_name,    :string,
        :p_aliases, :pointer,
        :p_proto,   :short
      )
    end

    # Wrapper for Protoent
    ProtoentStruct = Struct.new('Proto', :name, :aliases, :proto)

    class Hostent < FFI::Struct
      layout(
        :h_name, :string,
        :h_aliases, :pointer,
        :h_addrtype, :short,
        :h_length, :short,
        :h_addr_list, :pointer
      )
    end

    # Wrapper for Hostent
    HostStruct = Struct.new('Host', :name, :aliases, :addr_type, :addr_list)

    class Servent < FFI::Struct
      layout(
        :s_name, :string,
        :s_aliases, :pointer,
        :s_port, :short,
        :s_proto, :string
      )
    end

    class Addrinfo < FFI::Struct
      layout(
        :ai_flags, :int,
        :ai_family, :int,
        :ai_socktype, :int,
        :ai_protocol, :int,
        :ai_addrlen, :int,
        :ai_canonname, :string,
        :ai_addr, Sockaddr,
        :ai_next, :pointer
      )
    end

    class AddrinfoW < FFI::Struct
      layout(
        :ai_flags, :int,
        :ai_family, :int,
        :ai_socktype, :int,
        :ai_protocol, :int,
        :ai_addrlen, :size_t,
        :ai_canonname, :pointer,
        :ai_addr, Sockaddr,
        :ai_next, :pointer
      )
    end

    class AddrinfoEx < FFI::Struct
      layout(
        :ai_flags, :int,
        :ai_family, :int,
        :ai_socktype, :int,
        :ai_protocol, :int,
        :ai_addrlen, :int,
        :ai_canonname, :string,
        :ai_addr, Sockaddr,
        :ai_blob, :pointer,
        :ai_bloblen, :size_t,
        :ai_provider, GUID,
        :ai_next, :pointer
      )
    end
  end
end
