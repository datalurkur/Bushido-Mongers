#include "util/streambuffering.h"

void bufferToStream(ostringstream& stream, const char& value)   { genericBufferToStream(stream, value); }
void bufferFromStream(istringstream& stream, char& value)       { genericBufferFromStream(stream, value); }
void bufferToStream(ostringstream& stream, const short& value)  { genericBufferToStream(stream, value); }
void bufferFromStream(istringstream& stream, short& value)      { genericBufferFromStream(stream, value); }
void bufferToStream(ostringstream& stream, const int& value)    { genericBufferToStream(stream, value); }
void bufferFromStream(istringstream& stream, int& value)        { genericBufferFromStream(stream, value); }
void bufferToStream(ostringstream& stream, const float& value)  { genericBufferToStream(stream, value); }
void bufferFromStream(istringstream& stream, float& value)      { genericBufferFromStream(stream, value); }
void bufferToStream(ostringstream& stream, const double& value) { genericBufferToStream(stream, value); }
void bufferFromStream(istringstream& stream, double& value)     { genericBufferFromStream(stream, value); }
void bufferToStream(ostringstream& stream, const size_t& value) {
  genericBufferToStream(stream, (invariant_size)value);
}
void bufferFromStream(istringstream& stream, size_t& value)     {
  invariant_size temp;
  genericBufferFromStream(stream, temp);
  value = (size_t)temp;
}

void bufferToStream(ostringstream& stream, const string& value) {
  genericBufferToStream(stream, value.size());
  stream.write(value.c_str(), value.size());
}

void bufferFromStream(istringstream& stream, string& value) {
  invariant_size size;
  genericBufferFromStream(stream, size);

  char* buffer = new char[size];
  stream.read(buffer, size);
  value = string(buffer, size);
  delete buffer;
}
