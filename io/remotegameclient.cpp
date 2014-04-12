RemoteGameClient::RemoteGameClient(const NetAddress& addr, const string& name): ClientBase(), _addr(addr), _state(ClientState::Disconnected), _tcpBuffer(0), _name(name) {
}

RemoteGameClient::~RemoteGameClient() {
  disconnect();
}

ClientState RemoteGameClient::getState() const { return _state; }


void RemoteGameClient::protocolLoop() {
  Packet p;
  while(_stayAlive && _tcpBuffer->consumePacket(p)) {
    Payload* payload = Payload.Unpack(p.data, p.size);
  }
}
