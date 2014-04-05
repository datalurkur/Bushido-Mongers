#include "net/listensocket.h"
#include "util/assertion.h"
#include "util/log.h"

ListenSocket::ListenSocket(SocketCreationListener *acceptListener): Socket(true), _acceptListener(acceptListener), _shouldDie(false) {
}

ListenSocket::~ListenSocket() {
  stopListening();
}

bool ListenSocket::startListening(unsigned short localPort) {
  if(!_listenThread.joinable()) {
    if(!createSocket(SOCK_STREAM, IPPROTO_TCP)) { return false; }
    if(!bindSocket(localPort)) { return false; }

    // Listen for connections, setting the backlog to 5
    listen(_socketHandle, 5);

    // Start looping to accept connections
    _listenThread = thread(&ListenSocket::doListening, this);

    Info("Listening for connections on port " << localPort);

    return true;
  } else { return false; }
}

void ListenSocket::stopListening() {
  if(_listenThread.joinable()) {
    // Tell the thread to die
    _shouldDie = true;
    
    // Wait for the thread to die
    _listenThread.join();
    
    // Teardown
    closeSocket();

    Info("ListenSocked closed");
  }
}

void ListenSocket::doListening() {
  while(!_shouldDie) {
    sockaddr_in clientAddr;
    socklen_t clientAddrLength;
    int newSocketHandle;
    
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
