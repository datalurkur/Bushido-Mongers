#ifndef PACKET_H
#define PACKET_H

#include "util/timestamp.h"
#include "net/netaddress.h"

struct Packet {
  NetAddress addr;
  unsigned int size;
  char *data;
  clock_t clockStamp;

  Packet();
  Packet(const Packet &other);
  Packet(const NetAddress &a, const char *d, unsigned int s);
  ~Packet();

  const Packet& operator=(const Packet &rhs);
  bool operator<(const Packet &rhs) const;

private:
  void duplicate(const Packet &other);
};

#endif
