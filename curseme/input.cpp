#include "curseme/input.h"
#include "curseme/curseme.h"

void Input::GetWord(string& word) {
  string buffer = GetString();

  size_t index = buffer.find_first_of(' ');
  if(index != string::npos) { word = buffer.substr(0, index); }
  else { word = buffer; }
}

string Input::GetString() {
  if(CurseMe::Enabled()) {
    refresh();
    CurseMe::Cursor(true);
  }

  char input[256];
//  char[256] input;
  getnstr(input, 255);

  string str = string(input);
  return str;
}