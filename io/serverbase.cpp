#include "io/serverbase.h"
#include "io/gameevent.h"
#include "io/clientbase.h"

#include <unistd.h>

ServerBase::ServerBase(const string& rawSet): _nextPlayerID(0) {
  // In the future, we'll just pass a config file in here
  // The config file will dictate whether a world is generated or loaded, and what the details of generation are
  _core = new GameCore();
  setup(rawSet);
}

ServerBase::~ServerBase() {
  stop();
  delete _core;
}

void ServerBase::setup(const string& rawSet) {
  _core->generateWorld(rawSet);
}

void ServerBase::start() {
  if(_loopThread.joinable()) {
    Warn("Server is already running");
    return;
  }
  Info("Server starting");
  _shouldDie = false;
  _loopThread = thread(&ServerBase::innerLoop, this);
}

void ServerBase::stop() {
  if(!_loopThread.joinable()) {
    Warn("Server is not currently running");
    return;
  }
  Info("Server stopping");
  _shouldDie = true;
  _loopThread.join();
}

bool ServerBase::isRunning() {
  return _loopThread.joinable();
}

bool ServerBase::assignClient(ClientBase* client, const string& name) {
  #pragma message "A password should be used to validate a valid login"

  unique_lock<mutex> lock(_lock);

  auto existingClient = _assignedClients.find(name);
  if(existingClient != _assignedClients.end()) {
    Info("Player " << name << " already associated with a client");
    return false;
  }

  // Assign the client to its corresponding player login
  _assignedClients.insert(name, client);

  // Give the player an ID if they don't have one already
  auto playerIDItr = _playerIDs.find(name);
  if(playerIDItr == _playerIDs.end()) {
    PlayerID givenID = ++_nextPlayerID;
    _playerIDs[name] = givenID;
    _assignedIDs.insert(givenID, client);
    Info("Player " << name << " logging in for the first time, given ID " << givenID);
  } else {
    _assignedIDs.insert(playerIDItr->second, client);
    Info("Player " << name << " logging back in (ID " << playerIDItr->second << ")");
  }

  return true;
}

void ServerBase::removeClient(ClientBase* client) {
  unique_lock<mutex> lock(_lock);
  _assignedClients.reverseErase(client);
  _assignedIDs.reverseErase(client);
}

void ServerBase::clientEvent(ClientBase* client, GameEvent* event) {
  unique_lock<mutex> lock(_lock);

  auto playerIDItr = _assignedIDs.reverseFind(client);
  if(playerIDItr == _assignedIDs.reverseEnd()) {
    if(event->type == AssignName) {
      Info("Attempting to assign name to client");
      AssignNameEvent* e = (AssignNameEvent*)event;
      lock.unlock();
      if(!assignClient(client, e->name)) {
        Error("Failed to assign client to name " << e->name);
      } else {
        Info("Accepted client " << e->name);
      }
      return;
    } else {
      Error("Unassigned client attempting to send data to the server");
      return;
    }
  }
  PlayerID playerID = playerIDItr->second;

  auto clientNameItr = _assignedClients.reverseFind(client);
  if(clientNameItr == _assignedClients.reverseEnd()) {
    return;
  }
  string clientName = clientNameItr->second;
  Debug("Received client event from " << clientName << " (ID " << playerID << ")");

  EventMap<PlayerID> results;
  _core->processPlayerEvent(playerID, event, results);
  auto itr = results.begin();
  for(; itr != results.end(); itr++) {
  //for(auto queuePair : results) {
    auto clientPair = _assignedIDs.find(itr->first);
    if(clientPair == _assignedIDs.end()) {
      Error("Invalid PlayerID " << itr->first << " found in event map");
      continue;
    } else {
      Info("Sending mapped events to player " << itr->first);
    }
    ClientBase* thisClient = clientPair->second;
    thisClient->sendToClient(itr->second);
  }
}

void ServerBase::innerLoop() {
  clock_t last = clock();
  while(!_shouldDie) {
    // This will get removed once the game is in full swing
    sleep(1);

    Debug("...Server is thinking...");
    EventMap<PlayerID> updateEvents;

    unique_lock<mutex> lock(_lock);
    clock_t next = clock();
    _core->update(next - last, updateEvents);

    last = next;

    for(auto clientQueuePair : updateEvents) {
      auto clientPair = _assignedIDs.find(clientQueuePair.first);
      if(clientPair == _assignedIDs.end()) {
        Error("Invalid player ID " << clientQueuePair.first << " found in event map");
        continue;
      }
      ClientBase* thisClient = clientPair->second;
      thisClient->sendToClient(clientQueuePair.second);
    }
  }
}
