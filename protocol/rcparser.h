#ifndef RC_PARSER_H
#define RC_PARSER_H

#include <string>
#include <vector>

using namespace std;

struct RCField {
  string type;
  string name;
};

struct RCObject {
  string header;
  vector<RCField> fields;
};

class RCParser {
public:
  static bool ExtractObjects(const string& data, vector<RCObject>& objects);

private:
  static bool ExtractObjectDetails(const string& data, vector<RCObject>& objects);
  static bool ExtractObjectFields(const string& data, RCObject& object);
  static bool ExtractFieldDetails(const string& data, RCField& field);

private:
  static const char* Whitespace;
  static const char* Syntax;

private:
  RCParser();
};

#endif
