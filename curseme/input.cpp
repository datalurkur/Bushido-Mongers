#include "curseme/input.h"
#include "curseme/curseme.h"
#include "curseme/window.h"
#include <math.h>

void Input::GetWord(const string& title, string& word) {
  string buffer = GetString(title);

  size_t index = buffer.find_first_of(' ');
  if(index != string::npos) { word = buffer.substr(0, index); }
  else { word = buffer; }
}

string Input::GetString(const string& title) {
  int width_needed = (int)fmin(fmax(40, title.length()), 255);

  TitleBox tb = TitleBox(stdscr, 1, width_needed, 4, 4, title);
  tb.setup();

  // TODO - determine why wmove(tb->window(), 0, 0) doesn't always work (sometimes y is off-by-one)
  int y, x;
  getbegyx(tb.window(), y, x);
  wmove(stdscr, y, x);

  CurseMe::Cursor(true);
  char input[256];
  getnstr(input, 255);
  CurseMe::Cursor(false);

  tb.teardown();
  refresh();

  return string(input);
}
