#include <stdlib.h>
#include <stdio.h>
#include <signal.h>

#include <array>
#include <cstdlib>

#include <menu.h>

#include "curseme/curseme.h"
#include "curseme/menu.h"

void cleanup(int signal) {
  CurseMeTeardown();
  exit(signal);
}

int main(int argc, char** argv) {
  // Catch interrupts
  signal(SIGINT, cleanup);

  // Do curses setup
  CurseMeSetup();

  mvprintw(0, 0, "Make a selection");
  Menu menu(vector<string> { "Create New Raw", "Edit Existing Raw" });
  menu.prompt();

  cleanup(0);
}
