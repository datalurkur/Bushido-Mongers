#ifndef NETADDRESS_H
#define NETADDRESS_H

#include "net/socket.h"
#include <sstream>
using namespace std;

class NetAddress {
public:
  NetAddress();
  NetAddress(const char *addr, unsigned short port, unsigned char ipVersion = 4);
  NetAddress(const sockaddr_in *addrData);
  NetAddress(const sockaddr_in6 *addrData);
  ~NetAddress();

  const sockaddr *getSockAddr() const;
  unsigned int getSockAddrSize() const;

  inline const NetAddress& operator=(const NetAddress& rhs) {
    _ipv4Addr = rhs._ipv4Addr;
    _ipv6Addr = rhs._ipv6Addr;
    _ipVersion = rhs._ipVersion;
    return *this;
  }

  inline bool operator==(const NetAddress& rhs) const {
    return (_ipVersion == rhs._ipVersion) &&
       (  (_ipVersion == 4 &&
            (_ipv4Addr.sin_addr.s_addr == rhs._ipv4Addr.sin_addr.s_addr &&
             _ipv4Addr.sin_port        == rhs._ipv4Addr.sin_port)
          ) ||
          (_ipVersion == 6 &&
            (_ipv6Addr.sin6_addr.s6_addr == rhs._ipv6Addr.sin6_addr.s6_addr &&
             _ipv6Addr.sin6_port         == rhs._ipv6Addr.sin6_port)
          )
       );
  }

  inline bool operator!=(const NetAddress &rhs) const { return !(*this == rhs); }

  // Defined so NetAddress can be used as a key in map
  inline bool operator<(const NetAddress &rhs) const {
    if(_ipVersion == 4 && rhs._ipVersion == 4) {
      if(_ipv4Addr.sin_addr.s_addr == rhs._ipv4Addr.sin_addr.s_addr) {
        return (_ipv4Addr.sin_port < rhs._ipv4Addr.sin_port);
      } else {
        return (_ipv4Addr.sin_addr.s_addr < rhs._ipv4Addr.sin_addr.s_addr);
      }
    } else if(_ipVersion == 6 && rhs._ipVersion == 6) {
      if(_ipv6Addr.sin6_addr.s6_addr == rhs._ipv6Addr.sin6_addr.s6_addr) {
        return (_ipv6Addr.sin6_port < rhs._ipv6Addr.sin6_port);
      } else {
        return (_ipv6Addr.sin6_addr.s6_addr < rhs._ipv6Addr.sin6_addr.s6_addr);
      }
    } else if(_ipVersion == 4) {
      return true;
    } else {
      return false;
    }
  }

  void print(ostream &stream) const;

protected:
  sockaddr_in   _ipv4Addr;
  sockaddr_in6  _ipv6Addr;
  unsigned char _ipVersion;
};

ostream& operator<<(ostream& lhs, const NetAddress &rhs);

#endif
