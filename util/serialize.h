#ifndef SERIALIZE_H
#define SERIALIZE_H

#include "util/vector.h"

#include <sstream>
#include <string>

using namespace std;

extern ostream& operator<<(ostream& stream, const string& str);
extern istream& operator>>(istream& stream, string& str);

#endif
