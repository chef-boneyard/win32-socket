require 'ffi'

module Windows
  module WSASocketFunctions
    extend FFI::Library
    ffi_lib :ws2_32

    typedef :ulong, :dword
    typedef :uintptr_t, :socket

    attach_function :WSASocketA, [:int, :int, :int, :pointer, :int, :dword], :socket
    attach_function :WSACleanup, [], :int
    attach_function :WSAConnectEx, [:socket, :pointer, :int, :pointer, :pointer, :pointer, :pointer], :int
    attach_function :WSAGetLastError, [], :int
    attach_function :closesocket, [:socket], :int
  end
end
