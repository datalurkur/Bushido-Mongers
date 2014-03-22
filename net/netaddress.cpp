#include "net/netaddress.h"
#include <cstring>

NetAddress::NetAddress() {
}

NetAddress::NetAddress(const char *addr, unsigned short port, unsigned char ipVersion):
  _ipVersion(ipVersion) {
  if(_ipVersion == 4) {
    _ipv4Addr.sin_family = AF_INET;
    _ipv4Addr.sin_port = htons(port);
    inet_pton(AF_INET, addr, &_ipv4Addr.sin_addr);
  } else {
    _ipv6Addr.sin6_family = AF_INET6;
    _ipv6Addr.sin6_port = htons(port);
    inet_pton(AF_INET6, addr, &_ipv6Addr.sin6_addr);
  }
}

NetAddress::NetAddress(const sockaddr_in *addrData) {
  _ipVersion = 4;
  memcpy(&_ipv4Addr, addrData, sizeof(sockaddr_in));
}

NetAddress::NetAddress(const sockaddr_in6 *addrData) {
  _ipVersion = 6;
  memcpy(&_ipv6Addr, addrData, sizeof(sockaddr_in6));
}

NetAddress::~NetAddress() {}

const sockaddr *NetAddress::getSockAddr() const {
  return (_ipVersion == 4) ? (sockaddr*)&_ipv4Addr : (sockaddr*)&_ipv6Addr;
}

unsigned int NetAddress::getSockAddrSize() const {
  return (_ipVersion == 4) ? sizeof(sockaddr_in) : sizeof(sockaddr_in6);
}

void NetAddress::print(ostream &stream) const {
  stream << "NetAddress(";
  if(_ipVersion == 4) {
    char addrBuffer[INET_ADDRSTRLEN];
    inet_ntop(AF_INET, (void*)&(_ipv4Addr.sin_addr), addrBuffer, INET_ADDRSTRLEN);
    stream << addrBuffer << "(4):" << ntohs(_ipv4Addr.sin_port) << ")";
  } else {
    char addrBuffer[INET6_ADDRSTRLEN];
    inet_ntop(AF_INET6, (void*)&(_ipv6Addr.sin6_addr), addrBuffer, INET6_ADDRSTRLEN);
    stream << addrBuffer << "(6):" << ntohs(_ipv6Addr.sin6_port) << ")";
  }
}

ostream& operator<<(ostream& lhs, const NetAddress &rhs) {
  rhs.print(lhs);
  return lhs;
}
