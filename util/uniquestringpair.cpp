#include "util/uniquestringpair.h"

UniqueStringPair::UniqueStringPair(const string& a, const string& b) {
  _pair = (a > b) ? make_pair(a, b) : make_pair(b, a);
}

const string& UniqueStringPair::first() const { return _pair.first; }

const string& UniqueStringPair::second() const { return _pair.second; }

bool UniqueStringPair::operator<(const UniqueStringPair& other) const {
  return _pair < other._pair;
}
