#include "ui/prompt.h"
#include "ui/titlebox.h"

void Prompt::Popup(const string& message, Window* parent) {
  Window win(Window::CENTER, message.length() + 2, 3, 0, 0, parent);
  win.setBox();
  win.printText(1, 1, message.c_str());
  win.getChar();
}

bool Prompt::Word(const string& title, string& word, Window* parent) {
  string buffer;
  if(!Prompt::String(title, buffer, parent)) { return false; }

  size_t index = buffer.find_first_of(' ');
  if(index != string::npos) { word = buffer.substr(0, index); }
  else { word = buffer; }

  return true;
}

bool Prompt::String(const string& title, string& str, Window* parent) {
  int width_needed = (int)fmin(fmax(40, title.length()), 255);

  TitleBox box(Window::CENTER, width_needed, 1, title, parent);

  box.usableArea()->setCursorPosition(0, 0);
  CurseMe::Cursor(true);
  int ret = box.usableArea()->getString(str);
  CurseMe::Cursor(false);

  return (ret == OK);
}
