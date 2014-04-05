RemoteGameClient::RemoteGameClient(const NetAddress& addr, const string& name): ClientBase(), _addr(addr), _state(ClientState::Disconnected), _tcpBuffer(0), _name(name) {
}

RemoteGameClient::~RemoteGameClient() {
  disconnect();
}

ClientState RemoteGameClient::getState() const { return _state; }

bool RemoteGameClient::connect() {
  if(_state == ClientState::Disconnected) {
    _tcpBuffer = new TCPBuffer();

    if(_tcpBuffer->connect(_addr)) {
      _tcpBuffer->startBuffering();
      _state = ClientState::Waiting;

      _stayAlive = true;
      _protocolThread = thread(&RemoteGameClient::protocolLoop, this);

      return true;
    } else {
      delete _tcpBuffer;
      return false;
    }
  } else {
    Error("Client is already connected");
    return false;
  }
}

void RemoteGameClient::disconnect() {
  if(_state == ClientState::Disconnected) {
    Error("Client is not connected");
    return false;
  }

  _stayAlive = false;
  _protocolThread.join();
  _state = ClientState::Disconnected;

  _tcpBuffer->stopBuffering();
  delete _tcpBuffer;
  _tcpBuffer = 0;
}

void RemoteGameClient::protocolLoop() {
  Packet p;
  while(_stayAlive && _tcpBuffer->consumePacket(p)) {
    Payload* payload = Payload.Unpack(p.data, p.size);
  }
}
