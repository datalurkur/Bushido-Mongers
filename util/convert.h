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

template <typename T>
string ConvertNumeric(T& source) {
  ostringstream stream;
  stream << source;
  return source.str();
}

template <typename T>
string operator + (const string& lhs, const T& rhs) {
  ostringstream stream;
  stream << lhs << rhs;
  return stream.str();
}

#endif
