require 'ffi'

module Windows
  module WSASocketConstants
    # Address Family

    AF_UNSPEC = 0
    AF_INET = 2
    AF_IPX = 6
    AF_APPLETALK = 16
    AF_NETBIOS = 17
    AF_INET6 = 23
    AF_IRDA = 26
    AF_BTH = 32

    # Socket Types

    SOCK_STREAM = 1
    SOCK_DGRAM = 2
    SOCK_RAW = 3
    SOCK_RDM = 4
    SOCK_SEQPACKET = 5

    # Socket Protocols

    IPPROTO_ICMP = 1
    IPPROTO_IGMP = 2
    BTHPROTO_RFCOMM = 3
    IPPROTO_TCP = 6
    IPPROTO_UDP = 17
    IPPROTO_ICMPV6 = 58
    IPPROTO_RM = 113

    # Socket Groups

    SG_UNCONSTRAINED_GROUP = 1
    SG_CONSTRAINED_GROUP = 2

    # Flags

    WSA_FLAG_OVERLAPPED = 0x01
    WSA_FLAG_MULTIPOINT_C_ROOT = 0x02
    WSA_FLAG_MULTIPOINT_C_LEAF = 0x04
    WSA_FLAG_MULTIPOINT_D_ROOT = 0x08
    WSA_FLAG_MULTIPOINT_D_LEAF = 0x10
    WSA_FLAG_ACCESS_SYSTEM_SECURITY = 0x40
    WSA_FLAG_NO_HANDLE_INHERIT = 0x80

    # Errors

    INVALID_SOCKET_VALUE = (1<<FFI::Platform::ADDRESS_SIZE)-1
    SOCKET_ERROR = -1
  end
end
