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
  TitleBox* tb = TitleBox::from_parent(stdscr, 1, 40, 4, 4, title);
  wmove(tb->window(), 0, 0);
  refresh();

  CurseMe::Cursor(true);
  char input[256];
  getnstr(input, 255);
  CurseMe::Cursor(false);

  delete tb;
  refresh();

  return string(input);
}
