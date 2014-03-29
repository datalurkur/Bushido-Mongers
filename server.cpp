#include "curseme/renderer.h"
#include "util/log.h"
#include "game/core.h"

#include <signal.h>
#include <unistd.h>

using namespace std;

GameCore* core = 0;

void cleanup(int signal) {
  if(core) {
    delete core;
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

  core = new GameCore();

  #pragma message "Insert a menu here to allow the user to select the size of the world (small / medium / large / etc)"
  string rawSet(argv[1]);
  Info("Generating game using " << rawSet << " raws");
  core->generateWorld(argv[1], 10);

  core->start();
  while(core->isRunning()) {
    sleep(1);
  }

  cleanup(0);
}
