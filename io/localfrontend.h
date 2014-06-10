#ifndef LOCAL_FRONTEND_H
#define LOCAL_FRONTEND_H

#include "io/clientbase.h"

using namespace std;

class ServerBase;

class LocalFrontEnd: virtual public ClientBase {
public:
  LocalFrontEnd(ServerBase* server);
  virtual ~LocalFrontEnd();

  bool connectSender(const string& name);
  void disconnectSender();
  void sendToServer(GameEvent* event);

private:
  ServerBase* _server;
  string _name;
};

#endif
