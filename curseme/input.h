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
  static bool GetNumber(const string& title, T& value);
  static void GetWord(const string& title, string& word);

private:
  static string GetString(const string& title);
};

template <typename T>
bool Input::GetNumber(const string& title, T& value) {
  string buffer = GetString(title);
  return ConvertString<T>(buffer, value);
}

#endif