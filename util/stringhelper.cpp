#include "util/stringhelper.h"

#include <algorithm>
#include <cctype>
using namespace std;

// Without these, clang will fail to infer the "int toupper(int)" as the unary operator for a char on Linux (seems to work on OSX for some reason)
char tolower_char(char c) { return tolower(c); }
char toupper_char(char c) { return toupper(c); }

string ToUpcase(const string& str) {
  string ret(str);
  transform(ret.begin(), ret.end(), ret.begin(), toupper_char);
  return ret;
}

string ToDowncase(const string& str) {
  string ret(str);
  transform(ret.begin(), ret.end(), ret.begin(), tolower_char);
  return ret;
}

string ToClassName(const string& str) {
  string ret = ToDowncase(str);
  toupper(ret[0]);
  return ret;
}
