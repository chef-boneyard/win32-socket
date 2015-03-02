require 'ffi'
require_relative 'socket/constants'
require_relative 'socket/structs'
require_relative 'socket/functions'
require_relative 'socket/helper'

module Win32
  class WSASocket
    extend FFI::Library
    ffi_lib :ws2_32

    def initialize
    end
  end
end
