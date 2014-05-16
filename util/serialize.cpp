#include "util/serialize.h"

ostream& operator<<(ostream& stream, const string& str) {
  stream << str;
  return stream;
}

istream& operator>>(istream& stream, string& str) {
  size_t size;
  stream >> size;

  char* buffer = new char[size + 1];
  stream.read(buffer, size);
  buffer[size] = 0;
  str = string(buffer);
  delete buffer;

  return stream;
}
