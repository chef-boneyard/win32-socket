require 'ffi'

module Windows
  module WSASocketStructs
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
        :sin_zero [:char, 8]
      )
    end

    class WSAPROTOCOL_INFO < FFI::Struct
      extend FFI::Library

      typedef :ulong, :dword

      class WSAPROTOCOL_INFO < FFI::Struct
        layout(
          :dwServiceFlags1, :dword,
          :dwServiceFlags2, :dword,
          :dwServiceFlags3, :dword,
          :dwServiceFlags4, :dword,
          :dwProviderFlags, :dword,
          :ProviderID, :dword,
          :dwCatalogEntryId, :dword,
          :ProtocolChain, :dword,
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
          :szProtocol, [:char, 512]
        )
      end
    end
  end
end
