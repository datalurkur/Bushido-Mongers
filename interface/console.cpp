#include "interface/console.h"

void Console::GetWordInput(string& word) {
  string line;
  getline(cin, line);
  size_t index = line.find_first_of(' ');
  if(index != string::npos) { word = line.substr(0, index); }
  else { word = line; }
}
