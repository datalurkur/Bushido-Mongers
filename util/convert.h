#ifndef CONVERT_H
#define CONVERT_H

#include <string>
#include <sstream>

template <typename T>
extern bool ConvertString(const string& source, T& dest) {
  istringstream stream(source);
  return !(stream >> dest).fail();
}

#endif
