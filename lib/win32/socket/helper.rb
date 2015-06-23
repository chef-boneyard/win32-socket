require 'ffi'

class FFI::Pointer
  # Returns an array of strings for char** types.
  def read_array_of_string
    elements = []

    loc = self

    until ((element = loc.read_pointer).null?)
      elements << element.read_string
      loc += FFI::Type::POINTER.size
    end

    elements
  end
end

module FFI
  extend FFI::Library

  ffi_lib :kernel32

  attach_function :FormatMessage, :FormatMessageA,
    [:ulong, :pointer, :ulong, :ulong, :pointer, :ulong, :pointer], :ulong

  # Returns a Windows specific error message based on +err+ prepended
  # with the +function+ name. Note that this does not actually raise
  # an error, it only returns the message.
  #
  # The message will always be English regardless of your locale.
  #
  def win_error(function, err=FFI.errno)
    flags = 0x00001000 | 0x00000200 # ARGUMENT_ARRAY + SYSTEM
    buf = FFI::MemoryPointer.new(:char, 1024)

    # 0x0409 = MAKELANGID(LANG_ENGLISH, SUBLANG_ENGLISH_US)
    FormatMessage(flags, nil, err , 0x0409, buf, 1024, nil)

    function + ': ' + buf.read_string.strip
  end

  # Raises a Windows specific error using SystemCallError that is based on
  # the +err+ provided, with the message prepended with the +function+ name.
  #
  def raise_windows_error(function, err=FFI.errno)
    raise SystemCallError.new(win_error(function, err), err)
  end

  module_function :win_error
  module_function :raise_windows_error
end
