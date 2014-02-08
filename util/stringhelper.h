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

#endif
