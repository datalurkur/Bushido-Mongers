#ifndef LOCAL_FRONTEND_H
#define LOCAL_FRONTEND_H

#include "io/clientbase.h"

using namespace std;

class ServerBase;

class LocalFrontEnd: virtual public ClientBase {
public:
  LocalFrontEnd(ServerBase* server, const string& name);
  virtual ~LocalFrontEnd();

  bool connectSender();
  void disconnectSender();
  void sendEvent(const GameEvent* event);

private:
  ServerBase* _server;
  string _name;
};

#endif
