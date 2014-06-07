#include "io/remotegameclient.h"
#include "util/log.h"
#include "ui/prompt.h"

#include <signal.h>
#include <unistd.h>

using namespace std;

RemoteGameClient* client = 0;

void cleanup(int signal) {
  Info("Cleaning up");
  if(client) {
    delete client;
  }

  CurseMe::Teardown();
  Log::Teardown();

  exit(signal);
}

void setup() {
  Log::Setup("server.log");
  CurseMe::Setup();
  signal(SIGINT, cleanup);
}

int main(int argc, char** argv) {
  setup();

  if(argc < 3) {
    Prompt::Popup("Usage: client <name> <server address> [port]");
    cleanup(1);
  }

  string name(argv[1]);

  short port;
  if(argc == 3 || !ConvertString(argv[3], port)) {
    port = 9999;
  }
  NetAddress addr(argv[2], port);

  client = new RemoteGameClient(addr, name);
  if(!client->connectSender()) {
    Prompt::Popup("Failed to connect to server at " + string(argv[2]) + ":" + port);
    cleanup(1);
  }

  Info("Client is connected and ready to issue commands");
  string characterName = "Test Remote Character Name";
  client->createCharacter(characterName);
  sleep(1);

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

  client->disconnectSender();

  cleanup(0);
}
