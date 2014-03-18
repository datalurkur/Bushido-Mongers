#ifndef INPUT_H
#define INPUT_H

#include <string>
#include <iostream>
#include <string>

#include "util/convert.h"

using namespace std;

class Input {
public:
  template <typename T>
  static bool GetNumber(T& value);
  static void GetWord(string& word);

private:
  static string GetString();

  // Ensure this object can't be constructed
  Input();
};

template <typename T>
bool Input::GetNumber(T& value) {
  string buffer = GetString();
  return ConvertString<T>(buffer, value);
}

#endif