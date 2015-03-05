require 'ffi'

module Windows
  module WSASocketFunctions
    extend FFI::Library
    ffi_lib :ws2_32

    typedef :ulong, :dword
    typedef :uintptr_t, :socket
    typedef :pointer, :ptr

    attach_function :WSASocketA, [:int, :int, :int, :ptr, :int, :dword], :socket
    attach_function :WSACleanup, [], :int
    attach_function :WSAConnect, [:socket, :ptr, :int, :ptr, :ptr, :ptr, :ptr], :int
    attach_function :WSAConnectByNameA, [:socket, :string, :string, :ptr, :ptr, :ptr, :ptr, :ptr, :ptr], :int
    attach_function :WSAGetLastError, [], :int
    attach_function :closesocket, [:socket], :int
    attach_function :inet_addr, [:string], :ulong
  end
end
