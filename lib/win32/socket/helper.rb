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