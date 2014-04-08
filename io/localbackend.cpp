#include "io/localbackend.h"
#include "io/gameevent.h"

LocalBackEnd::LocalBackEnd() {}
LocalBackEnd::~LocalBackEnd() {}

void LocalBackEnd::receiveEvent(const GameEvent& event) { processEvent(event); }
