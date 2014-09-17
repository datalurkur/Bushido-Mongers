#include "io/gameserver.h"

GameServer::GameServer(const string& rawSet, unsigned short listenPort): ServerBase(rawSet), _listenSocket(this) {
  _listenSocket.startListening(listenPort);
}

GameServer::~GameServer() {
  _listenSocket.stopListening();

  Debug("Tearing down remote clients");
  for(auto remoteClient : _remoteClients) {
    delete remoteClient;
  }
  _remoteClients.clear();
}

bool GameServer::onSocketCreation(const NetAddress &client, TCPSocket *socket) {
  RemoteClientStub* stub = new RemoteClientStub(this, socket);
  _remoteClients.push_back(stub);
  Info("New remote client connected, awaiting name assignment");
  return true;
}
