#include "curseme/renderer.h"
#include "util/log.h"
#include "io/gameserver.h"
#include "io/localgameclient.h"

#include <signal.h>
#include <unistd.h>

using namespace std;

GameServer* server = 0;
LocalGameClient* client = 0;

void cleanup(int signal) {
  if(client) {
    delete client;
  }
  if(server) {
    delete server;
  }

  CurseMeTeardown();
  Log::Teardown();

  exit(signal);
}

void setup() {
  Log::Setup("stdout");
  CurseMeSetup();
  signal(SIGINT, cleanup);
}

int main(int argc, char** argv) {
  setup();

  if(argc < 2) {
    #pragma message "Insert a popup here explaining why we're exiting"
    cleanup(1);
  }

  #pragma message "The creation of the server will eventually be controllable via config files"
  server = new GameServer(string(argv[1]));
  server->start();

  #pragma message "Create a prompt to get client login / issue commands to the server directly"
  // For now, we'll just test out local client stuff
  string clientName = "Test Client Name";
  client = new LocalGameClient(server, clientName);
  if(!client->connectSender()) {
    Error("Failed to connect local client to server");
    cleanup(1);
  }

  #pragma message "This should be a menu..."
  Info("Client is connected and ready to issue commands");
  string characterName = "Test Character Name";
  client->createCharacter(characterName);

  while(true) {
    sleep(1);
  }

  cleanup(0);
}
