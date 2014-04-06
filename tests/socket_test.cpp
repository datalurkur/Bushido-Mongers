#include "net/tcpsocket.h"
#include "net/listensocket.h"
#include "util/log.h"
#include "util/timestamp.h"

#include <atomic>

int numPackets = 3;
int clientPacketSize = 4;
int serverPacketSize = 5;
int clientBytes = numPackets * clientPacketSize;
int serverBytes = numPackets * serverPacketSize;

atomic<PreciseClock> start;

class FakeServer: public SocketCreationListener {
public:
  FakeServer(): _socket(0) {}
  ~FakeServer() {
    if(_socket) { delete _socket; }
  }

  bool onSocketCreation(const NetAddress& client, TCPSocket* socket) {
    Info("Creating server threads");
    _socket = socket;
    _sendThread = thread(&FakeServer::sendRandomPackets, this);
    _recvThread = thread(&FakeServer::receivePackets, this);
    return true;
  }

  void waitForFinish() {
    while(!_sendThread.joinable()) { sleep(1); }
    _sendThread.join();
    _recvThread.join();
  }

  void sendRandomPackets() {
    Info("Spawning server send thread");
    char* buffer = (char*)calloc(serverPacketSize, sizeof(char));
    for(int c = 0; c < numPackets; c++) {
      sleep(1);
      for(int d = 0; d < serverPacketSize; d++) { buffer[d] = '0' + c; }
      Info("-> (" << Clock.getElapsedSeconds(start) << ") Server sending data");
      _socket->send(buffer, serverPacketSize);
    }
    free(buffer);
    Info("Server done sending data");
  }

  void receivePackets() {
    char buffer[16];
    int size;
    int count = 0;
    while(count < clientBytes) {
      if(!_socket->recvBlocking((char*)&buffer[0], size, 16)) { continue; }
      Info("<- (" << Clock.getElapsedSeconds(start) << ") Received " << size << " bytes of data from client");
      printf("\t");
      for(int c = 0; c < size; c++) { printf("%c", buffer[c]); }
      printf("\n");
      count += size;
    }
    Info("Server done receiving data");
  }

private:
  TCPSocket* _socket;
  thread _sendThread, _recvThread;
};

TCPSocket* client;

void sendSlowly() {
  Info("Spawning client send thread");
  char* buffer = (char*)calloc(clientPacketSize, sizeof(char));
  for(int c = 0; c < numPackets; c++) {
    sleep(4);
    for(int d = 0; d < clientPacketSize; d++) { buffer[d] = '0' + c; }
    Info("-> (" << Clock.getElapsedSeconds(start) << ") Client sending data");
    client->send(buffer, clientPacketSize);
  }
  free(buffer);
  Info("Client done sending data");
}

int main() {
  Log::Setup();
  start = Clock.getMonotonicClock();

  FakeServer server;
  ListenSocket listener(&server);
  listener.startListening(9876);
  client = new TCPSocket();
  if(!client->connectSocket(NetAddress("127.0.0.1", 9876))) {
    Info("Failed to connect");
    listener.stopListening();
    Log::Teardown();
    return 1;
  } else {
    Info("Client connected");
  }
  sleep(1);
  listener.stopListening();
  Info("Preparing client send / receive magic");
  thread slowThread;
  slowThread = thread(sendSlowly);
  int count = 0;
  char buffer[16];
  int size;
  while(count < serverBytes) {
    if(!client->recvBlocking((char*)&buffer[0], size, 16)) { continue; }
    Info("<- (" << Clock.getElapsedSeconds(start) << ") Received " << size << " bytes from server");
    printf("\t");
    for(int c = 0; c < size; c++) { printf("%c", buffer[c]); }
    printf("\n");
    count += size;
  }
  Info("Client done receiving data");
  Info("Waiting for threads to join");
  slowThread.join();
  server.waitForFinish();
  Log::Teardown();
  return 0;
}
