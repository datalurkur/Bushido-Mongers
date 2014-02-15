#ifndef CONSOLE_H
#define CONSOLE_H

#include "util/convert.h"

#include <iostream>
#include <string>

using namespace std;

class Console {
public:
  template <typename T>
  static bool GetNumericInput(T& value);
  static void GetWordInput(string& word);

private:
  // Ensure this object can't be constructed
  Console();
};

template <typename T>
bool Console::GetNumericInput(T& value) {
  string buffer;
  getline(cin, buffer);
  return ConvertString<T>(buffer, value);
}

#endif
