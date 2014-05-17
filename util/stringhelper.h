#ifndef STRING_HELPER_H
#define STRING_HELPER_H

#include <string>
using namespace std;

template <typename T>
void TokenizeString(const string &source, const string &delims, T &tokens) {
  size_t token_begin, token_end;

  // Get the first line
  token_begin = source.find_first_not_of(delims);
  token_end   = source.find_first_of(delims, token_begin);

  // Parse the lines
  while(token_begin != string::npos) {
    tokens.push_back(source.substr(token_begin, token_end - token_begin));

    // Get the next line
    token_begin = source.find_first_not_of(delims, token_end);
    token_end   = source.find_first_of(delims, token_begin);
  }
}

extern string ToUpcase(const string& str);
extern string ToDowncase(const string& str);
extern string ToClassName(const string& str);

/*
typedef pair<string, string> StringPair;

// A hash method for StringPair, so we can use it as a key-type for an unordered_map.
template<>
struct hash<StringPair> {
  size_t operator()(const StringPair &sp) const {
    return hash<string>()(sp.first) ^ hash<string>()(sp.second);
  }
};
typedef unordered_map<StringPair, function<void()> > StringPairFunctionMap;
*/

#endif
