#include "util/streambuffering.h"

// string implementation
template <>
void bufferToStream(ostringstream& stream, const string& value) {
  bufferToStream(stream, value.size());
  stream.write(value.c_str(), value.size());
}

template <>
void bufferFromStream(istringstream& stream, string& value) {
  auto size = value.size();
  bufferFromStream(stream, size);

  char* buffer = new char[size];
  stream.read(buffer, size);
  value = string(buffer, size);
  delete buffer;
}
