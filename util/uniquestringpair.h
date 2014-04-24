#ifndef UNIQUE_STRINGPAIR_H
#define UNIQUE_STRINGPAIR_H

#include <utility>
#include <string>

using namespace std;

class UniqueStringPair {
public:
  UniqueStringPair(const string& a, const string& b);

  const string& first() const;
  const string& second() const;

  bool operator<(const UniqueStringPair& other) const;

protected:
  pair<string,string> _pair;
};

#endif
