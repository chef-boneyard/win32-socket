require 'ffi'

module Windows
  module WSASocketFunctions
    extend FFI::Library

    typedef :ulong, :dword
    typedef :uintptr_t, :socket
    typedef :pointer, :ptr
    typedef :ushort, :word
    typedef :uintptr_t, :handle

    ffi_lib :kernel32

    attach_function :SleepEx, [:dword, :bool], :dword

    ffi_lib :ws2_32

    attach_function :closesocket, [:socket], :int
    attach_function :inet_addr, [:string], :ulong
    attach_function :GetProtoByName, :getprotobyname, [:string], :ptr
    attach_function :GetProtoByNumber, :getprotobynumber, [:int], :ptr

    attach_function :WSAAsyncGetHostByAddr, [:uintptr_t, :uint, :string, :int, :int, :buffer_out, :int], :uintptr_t
    attach_function :WSAAsyncGetHostByName, [:uintptr_t, :uint, :string, :buffer_out, :pointer], :uintptr_t
    attach_function :WSAAsyncGetProtoByName, [:uintptr_t, :uint, :string, :buffer_out, :pointer], :uintptr_t
    attach_function :WSAAsyncGetProtoByNumber, [:uintptr_t, :uint, :int, :buffer_out, :pointer], :uintptr_t
    attach_function :WSAAsyncGetServByName, [:uintptr_t, :uint, :int, :string, :buffer_out, :int], :uintptr_t
    attach_function :WSAAsyncGetServByPort, [:uintptr_t, :uint, :int, :string, :buffer_out, :int], :uintptr_t
    attach_function :WSACancelAsyncRequest, [:uintptr_t], :int
    attach_function :WSACleanup, [], :int
    attach_function :WSAConnect, [:socket, :ptr, :int, :ptr, :ptr, :ptr, :ptr], :int
    attach_function :WSAConnectByNameA, [:socket, :string, :string, :ptr, :ptr, :ptr, :ptr, :ptr, :ptr], :bool
    attach_function :WSAEnumNameSpaceProvidersA, [:ptr, :ptr], :int
    attach_function :WSAEnumProtocolsA, [:ptr, :ptr, :ptr], :int
    attach_function :WSAGetLastError, [], :int
    attach_function :WSASocketA, [:int, :int, :int, :ptr, :int, :dword], :socket
    attach_function :WSAStartup, [:word, :ptr], :int
  end
end
