#include "io/localgameclient.h"

LocalGameClient::LocalGameClient(ServerBase* server, const string& name): LocalFrontEnd(server, name) {}

LocalGameClient::~LocalGameClient() {}
