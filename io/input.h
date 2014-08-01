#include <chrono>
#include <thread>

#include "io/clientbase.h"
#include "curseme/curseme.h"

enum Action {
  None,
  MoveNorth,
  MoveNorthEast,
  MoveEast,
  MoveSouthEast,
  MoveSouth,
  MoveSouthWest,
  MoveWest,
  MoveNorthWest
};

void input_poll(WINDOW* input_window, ClientBase* client);
void send_action(ClientBase* client, Action action);
