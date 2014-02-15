#ifndef CONVERT_H
#define CONVERT_H

#include <string>
#include <sstream>

using namespace std;

template <typename T>
bool ConvertString(const string& source, T& dest) {
  istringstream stream(source);
  return !(stream >> dest).fail();
}

#endif
