#include "util/stringhelper.h"

#include <algorithm>
using namespace std;

string ToUpcase(const string& str) {
  string ret(str);
  transform(ret.begin(), ret.end(), ret.begin(), toupper);
  return ret;
}

string ToDowncase(const string& str) {
  string ret(str);
  transform(ret.begin(), ret.end(), ret.begin(), tolower);
  return ret;
}

string ToClassName(const string& str) {
  string ret = ToDowncase(str);
  toupper(ret[0]);
  return ret;
}
