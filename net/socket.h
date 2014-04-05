#ifndef SOCKET_H
#define SOCKET_H

#include "util/platform.h"

#if SYS_PLATFORM == PLATFORM_WIN32
# include <winsock2.h>
# include <ws2tcpip.h>
# define E_ADDR_IN_USE WSAEADDRINUSE
# define E_ALREADY WSAEINPROGRESS
# define E_IN_PROGRESS WSAEWOULDBLOCK
# pragma comment(lib, "Ws2_32.lib")
#else
# include <errno.h>
# include <sys/socket.h>
# include <unistd.h>
# include <netinet/in.h>
# include <fcntl.h>
# include <arpa/inet.h>
# define E_ADDR_IN_USE EADDRINUSE
# define E_ALREADY EALREADY
# define E_IN_PROGRESS EINPROGRESS
#endif

#include <mutex>
using namespace std;

class Socket {
public:
  static bool InitializeSocketLayer();
  static void ShutdownSocketLayer();
  static bool IsSocketLayerReady();

  static int LastSocketError();

private:
  static bool SocketLayerInitialized;

public:
  Socket(bool blocking);
  virtual ~Socket();
  
  bool isOpen();

  unsigned short getLocalPort();
  bool setBlockingFlag(bool value = true);

  bool send(const char *data, unsigned int size, const sockaddr *addr, int addrSize);
  void recv(char *data, int &size, unsigned int maxSize, sockaddr *addr, int &addrSize);

protected:
  bool createSocket(int type, int proto = 0);
  bool bindSocket(unsigned short localPort);
  void closeSocket();

protected:
  typedef unsigned char SocketState;
  enum SocketStates {
    Uninitialized = 0,
    Created,
    Bound,
    Listening,
    Connecting,
    Connected
  };

protected:
  mutex _mutex;

  SocketState _state;
  bool _blocking;
  int _socketHandle;
};

#endif
