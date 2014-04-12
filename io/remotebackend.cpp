#include "io/remotebackend.h"
#include "io/gameevent.h"

RemoteBackEnd::RemoteBackEnd() {}
RemoteBackEnd::~RemoteBackEnd() {}

void RemoteBackEnd::sendToClient(GameEvent* event) {
  #pragma message "GameEvent packing code will go here"
}
