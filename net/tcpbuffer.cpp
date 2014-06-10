#include "net/tcpbuffer.h"
#include "util/packing.h"

PacketBufferInfo::PacketBufferInfo():
  size(0), offset(0), hasSize(false), str(ios_base::binary) {
}

TCPBuffer::TCPBuffer(size_t bufferSize): _bufferSize(bufferSize) {
  _buffer = new char[bufferSize];
}

TCPBuffer::~TCPBuffer() {
  delete _buffer;
}

void TCPBuffer::sendPacket(TCPSocket* socket, const ostringstream& str) {
  string data = str.str();
  size_t size = data.size();
  const char* cstr = data.c_str();

  // Send the payload size ahead of time
  socket->send((char*)&size, sizeof(size_t));

  // Send the actual payload, one chunk at a time
  size_t offset = 0;
  while(offset < size) {
    size_t chunkSize = min(size - offset, _bufferSize);
    socket->send(&cstr[offset], chunkSize);
    offset += chunkSize;
  }
}

bool TCPBuffer::getPacket(TCPSocket* socket, PacketBufferInfo& i) {
  if(i.hasSize) {
    size_t maxSize = min(_bufferSize, i.size - i.offset);
    int s;
    if(socket->recvBlocking(_buffer, s, maxSize, 1) && s > 0) {
      string data(_buffer, s);
      i.offset += s;
      i.str << data;
      return (i.offset == i.size);
    } else {
      return false;
    }
  } else {
    int s;
    if(socket->recvBlocking((char*)&(i.size), s, sizeof(i.size), 1) && s > 0) {
      // We have a size, but the packet is not ready yet
      i.hasSize = true;
      return false;
    } else {
      return false;
    }
  }
}
