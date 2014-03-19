#include <curses.h>
#include "curseme/input.h"
#include "curseme/curseme.h"

void Input::GetWord(string& word) {
  string buffer = GetString();

  size_t index = buffer.find_first_of(' ');
  if(index != string::npos) { word = buffer.substr(0, index); }
  else { word = buffer; }
}

string Input::GetString() {
  refresh();
  CurseMe::Cursor(true);

  char input[256];
  getnstr(input, 255);

  return string(input);
}