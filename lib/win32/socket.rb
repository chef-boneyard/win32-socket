require 'ffi'

module Win32
  class WSASocket
    extend FFI::Library
    ffi_lib :ws2_32

    def initialize
    end
  end
end
