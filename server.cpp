#include "curseme/window.h"
#include "util/log.h"
#include "io/gameserver.h"
#include "io/localgameclient.h"

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

  CurseMeTeardown();
  Log::Teardown();

  exit(signal);
}

void setup() {
  Log::Setup("server.log");
  CurseMeSetup();
  signal(SIGINT, cleanup);
}

int main(int argc, char** argv) {
  setup();

  if(argc < 2) {
    Popup("usage: server <raws directory>");
    cleanup(1);
  }

  #pragma message "The creation of the server will eventually be controllable via config files"
  server = new GameServer(string(argv[1]));
  server->start();

  #pragma message "Create a prompt to get client login / issue commands to the server directly"
/*
  Menu clientInput("Server active at server->ip():server->post()", [&](menu clientInput) {
    clientInput.addChoice("Use Client", [&] {
      CursesClient cc();
      string clientName;
      Input::GetWord("Username:", clientName);
    }
  }
*/
  // For now, we'll just test out local client stuff
  string clientName = "Test Client Name";
  client = new LocalGameClient(server, clientName);
  if(!client->connectSender()) {
    Error("Failed to connect local client to server");
    cleanup(1);
  }

  Info("Client is connected and ready to issue commands");
  string characterName = "Test Character Name";
  client->createCharacter(characterName);

  // Test movement
  Info("Client is attempting to move");
  Info("=======================================");
  client->moveCharacter(IVec2(1, 0));
  sleep(1);
  Info("=======================================");
  client->moveCharacter(IVec2(-1, 0));
  sleep(1);
  Info("=======================================");
  client->moveCharacter(IVec2(0, 1));
  sleep(1);
  Info("=======================================");
  client->moveCharacter(IVec2(0, -1));

  string testString(128, 'q');
  while(server->isRunning()) {
    sleep(1);
    Debug(testString << Vec2(0.5f, 0.7f) << testString);
  }

  cleanup(0);
}
