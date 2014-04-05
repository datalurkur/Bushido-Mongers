#ifndef TCPBUFFER_H
#define TCPBUFFER_H

#include "net/connectionbuffer.h"
#include "net/tcpsocket.h"

class TCPBuffer: public ConnectionBuffer {
public:
  TCPBuffer(unsigned short localPort = 0);
  TCPBuffer(TCPSocket *establishedSocket);
  virtual ~TCPBuffer();

  bool isConnected();
  bool connect(const NetAddress& dest);

  void startBuffering();
  void stopBuffering();

protected:
  void doInboundBuffering();
  void doOutboundBuffering();

private:
  // Make sure the Socket* is properly cast so the correct functions get called
  inline TCPSocket *getSocket() { return (TCPSocket*)_socket; }

  int tcpSerialize(char *dest, const char *src, unsigned int size, unsigned int maxSize);
  int tcpDeserialize(const char *srcData, char **data, unsigned int &size);

private:
  char *_serializationBuffer;
  unsigned short _localPort;
};

#endif
