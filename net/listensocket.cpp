#include "net/listensocket.h"
#include "util/assertion.h"
#include "util/log.h"

int InvokeListenSocketLoop(void *params) {
  ListenSocket *socket = (ListenSocket*)params;
  socket->doListening();
  return 1;
}

ListenSocket::ListenSocket(SocketCreationListener *acceptListener): Socket(true), _acceptListener(acceptListener), _listenThread(0), _listenMutex(0), _shouldDie(false) {
}

ListenSocket::~ListenSocket() {
  stopListening();
}

bool ListenSocket::startListening(unsigned short localPort) {
  if(!_listenThread) {
    if(!createSocket(SOCK_STREAM, IPPROTO_TCP)) { return false; }
    if(!bindSocket(localPort)) { return false; }

    // Listen for connections, setting the backlog to 5
    _mutex->lock();
    listen(_socketHandle, 5);
    _mutex->unlock();

    // Start looping to accept connections
    _listenMutex = new mutex;
    _listenThread = new thread(InvokeListenSocketLoop, (void*)this);

    Info("Listening for connections on port " << localPort);

    return true;
  } else { return false; }
}

void ListenSocket::stopListening() {
  if(_listenThread) {
    // Tell the thread to die
    _listenMutex->lock();
    _shouldDie = true;
    _listenMutex->unlock();
    
    // Wait for the thread to die
    _listenThread->join();
    delete _listenThread;
    _listenThread = 0;
    
    // Teardown
    delete _listenMutex;
    _listenMutex = 0;
    closeSocket();

    Info("ListenSocked closed");
  }
}

void ListenSocket::doListening() {
  while(true) {
    sockaddr_in clientAddr;
    socklen_t clientAddrLength;
    int newSocketHandle;
    
    _listenMutex->lock();
    if(_shouldDie) {
        _listenMutex->unlock();
        break;
    } else {
        _listenMutex->unlock();
    }

    clientAddrLength = sizeof(clientAddr);
    newSocketHandle = accept(_socketHandle, (sockaddr*)&clientAddr, &clientAddrLength);

    if(newSocketHandle <= 0) {
        // Fail gracefully and go on to processing the next connection
        //Error("ListenSocket failed to accept incoming connection");
        continue;
    }

    NetAddress clientAddress(&clientAddr);
    Info("Incoming connection from " << clientAddress);

    TCPSocket *newSocket = new TCPSocket(newSocketHandle, false);
    newSocket->setBlockingFlag(false);
    if(!_acceptListener->onSocketCreation(clientAddress, newSocket)) {
      delete newSocket;
    }
  }
}
