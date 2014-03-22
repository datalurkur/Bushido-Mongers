#ifndef TCPBUFFER_H
#define TCPBUFFER_H

#include "net/connectionbuffer.h"
#include "net/tcpsocket.h"

class TCPBuffer: public ConnectionBuffer {
public:
  TCPBuffer(const NetAddress &dest, unsigned short localPort = 0);
  TCPBuffer(const NetAddress &dest, TCPSocket *establishedSocket);
  virtual ~TCPBuffer();

  void startBuffering();
  void stopBuffering();

  void doInboundBuffering();
  void doOutboundBuffering();

  int tcpSerialize(char *dest, const char *src, unsigned int size, unsigned int maxSize);
  int tcpDeserialize(const char *srcData, char **data, unsigned int &size);

private:
  // Make sure the Socket* is properly cast so the correct functions get called
  inline TCPSocket *getSocket() { return (TCPSocket*)_socket; }

private:
  char *_serializationBuffer;
  NetAddress _dest;
};

#endif
