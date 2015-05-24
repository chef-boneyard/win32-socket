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
        :sin_zero, [:char, 8]
      )
    end

    # TODO: Get sizes without creating pointer
    sa_family_t = FFI::MemoryPointer.new(:uint)

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
