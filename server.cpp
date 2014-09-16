#include "io/gameserver.h"
#include "io/localgameclient.h"
#include "ui/prompt.h"
#include "util/log.h"
#include "state/gamestate.h"

#include <signal.h>
#include <unistd.h>

using namespace std;

GameServer* server = 0;
LocalGameClient* client = 0;

void cleanup(int signal) {
  Info("Cleaning up");
  if(client) {
    delete client;
  }
  if(server) {
    delete server;
  }
  GameEvent::FinishTrackingAllocations();
  CurseMe::Teardown();
  Log::Teardown();

  exit(signal);
}

void setup() {
  Log::Setup("server.log");
  CurseMe::Setup();
  GameEvent::BeginTrackingAllocations();
  signal(SIGINT, cleanup);
}

int main(int argc, char** argv) {
  setup();

  if(argc < 2) {
    Prompt::Popup("Usage: server <raws directory> [port]");
    cleanup(1);
  }

  unsigned short port;
  if(argc < 3 || !ConvertString(string(argv[2]), port)) {
    port = 9999;
  }

  #pragma message "The creation of the server will eventually be controllable via config files"
  server = new GameServer(string(argv[1]), port);
  server->start();

  #pragma message "Create a prompt to get client login / issue commands to the server directly"
  // For now, we'll just test out local client stuff
  string clientName = "Test Client Name";
  client = new LocalGameClient(server);
  if(!client->connectSender(clientName)) {
    Error("Failed to connect local client to server");
    cleanup(1);
  }

  Info("Client is connected and ready to issue commands");
  string characterName = "Test Character Name";
  client->sendToServer(new CreateCharacterEvent(characterName));
  sleep(1);

  GameState gameState(client);
  while(gameState.execute() && client->isConnected()) {
  }

  cleanup(0);
}
