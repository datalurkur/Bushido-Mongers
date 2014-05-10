#ifndef PROMPT_H
#define PROMPT_H

#include "curseme/window.h"
#include "util/convert.h"

#include <string>
using namespace std;

class Prompt {
public:
  static void Popup(const string& message, Window* parent = 0);

  template <typename T>
  static bool Number(const string& title, T& value, Window* parent = 0);

  static bool Word(const string& title, string& word, Window* parent = 0);

private:
  static bool String(const string& title, string& str, Window* parent = 0);

private:
  // Not to be instantiated
  Prompt() {}
};

template <typename T>
bool Prompt::Number(const string& title, T& value, Window* parent) {
  string buffer;
  if(Prompt::String(title, buffer, parent)) {
    return ConvertString<T>(buffer, value);
  } else {
    return false;
  }
}

#endif
