#ifndef TCPBUFFER_H
#define TCPBUFFER_H

#include "net/tcpsocket.h"

struct PacketBufferInfo {
  size_t size;
  size_t offset;
  bool hasSize;
  ostringstream str;

  PacketBufferInfo();
};

class TCPBuffer {
public:
  TCPBuffer(size_t bufferSize = 8192);
  ~TCPBuffer();

  void sendPacket(TCPSocket* socket, const ostringstream& str);
  bool getPacket(TCPSocket* socket, PacketBufferInfo& i);

private:
  size_t _bufferSize;
  char* _buffer;
};

#endif
