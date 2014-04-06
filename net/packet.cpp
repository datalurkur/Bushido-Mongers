#include "net/packet.h"
#include "util/assertion.h"
#include "util/log.h"

#include <cstring>

Packet::Packet(): size(0), data(0) {
}

Packet::Packet(const Packet &other): size(0), data(0), timestamp(0) {
  duplicate(other);
}

Packet::Packet(const char *d, unsigned int s): size(s) {
  data = (char*)calloc(s, sizeof(char));
  memcpy(data, d, s);
  timestamp = Clock.getTime();
}

Packet::~Packet() {
  if(data) {
    free(data);
    data = 0;
  }
}

#pragma message "Implement move semantics for this"
const Packet& Packet::operator=(const Packet &rhs) {
  duplicate(rhs);
  return *this;
}

bool Packet::operator<(const Packet &rhs) const {
  // We want the packet with the oldest (lowest) timestamp to have the greatest (highest) priority
  return (timestamp > rhs.timestamp);
}

void Packet::duplicate(const Packet &other) {
  if(data) {
    free(data);
    data = 0;
  }
  timestamp = other.timestamp;
  size = other.size;
  data = (char*)calloc(size, sizeof(char));
  memcpy(data, other.data, size);
}
