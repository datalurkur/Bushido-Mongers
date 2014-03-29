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
    cleanup(1);
  }

  core = new GameCore(argv[1]);

  cleanup(0);
}
