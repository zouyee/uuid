# uuid
**development** status
The uuid package generates and inspects UUIDs based on
[RFC 9562](https://datatracker.ietf.org/doc/html/rfc9562)
and DCE 1.1: Authentication and Security Services.

This package is **inspired** by the github.com/google/uuid package (previously named
code.google.com/p/go-uuid).  It differs from these earlier packages in that
a UUID is a 16 byte array rather than a byte slice.  One loss due to this
change is the ability to represent an invalid UUID (vs a NIL UUID).


###### Documentation

Full `zig doc` style documentation for the package can be viewed online
