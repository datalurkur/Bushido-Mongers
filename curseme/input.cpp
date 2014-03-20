#include <curses.h>
#include "curseme/input.h"
#include "curseme/curseme.h"
#include "curseme/window.h"

void Input::GetWord(const string& title, string& word) {
  string buffer = GetString(title);

  size_t index = buffer.find_first_of(' ');
  if(index != string::npos) { word = buffer.substr(0, index); }
  else { word = buffer; }
}

string Input::GetString(const string& title) {
  // FIXME: NO MAGIC NUMBERS
  TitleBox tb = TitleBox(subwin(stdscr, 5, 40, 4, 4), title);
  wmove(tb.window(), 0, 0);
  refresh();

  CurseMe::Cursor(true);
  char input[256];
  getnstr(input, 255);
  CurseMe::Cursor(false);

  tb.teardown();
  refresh();

  return string(input);
}
