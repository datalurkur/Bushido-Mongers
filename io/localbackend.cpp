#include "io/localbackend.h"
#include "io/gameevent.h"

LocalBackEnd::LocalBackEnd() {}
LocalBackEnd::~LocalBackEnd() {}

void LocalBackEnd::sendToClient(GameEvent* event) { processEvent(event); }
