require 'ffi'

module Windows
  module WSASocketStructs
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
