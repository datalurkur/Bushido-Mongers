#include "protocol/rcparser.h"
#include "util/log.h"

const char* RCParser::Whitespace = " \r\n\t";
const char* RCParser::Syntax = "{};";

bool RCParser::ExtractObjects(const string& data, vector<RCObject>& objects) {
  int scope = 0;

  size_t token_begin = data.find_first_not_of(Syntax),
         token_end   = data.find_first_of(Syntax, token_begin);

  while(token_begin != string::npos && token_end != string::npos) {
    switch(data[token_end]) {
      case '{':
        scope++;
        break;
      case '}':
        scope--;
        if(scope < 0) {
          Debug("Mismatched braces");
          return false;
        }
        break;
      case ';':
        if(scope == 0) {
          string tokenData = data.substr(token_begin, token_end - token_begin);
          size_t actual_begin = tokenData.find_first_not_of(Whitespace),
                 actual_end   = tokenData.find_last_not_of(Whitespace);
          if(actual_begin == string::npos || actual_end == string::npos) {
            Debug("Failed to trim whitespace from token " << tokenData);
            return false;
          }
          string token = tokenData.substr(actual_begin, actual_end - actual_begin + 1);

          ExtractObjectDetails(token, objects);

          token_begin = data.find_first_not_of(Syntax, token_end);
          token_end   = data.find_first_of(Syntax, token_begin);

          continue;
        }
        break;
      default:
        Debug("Invalid character found at index " << token_end << " (" << data[token_end] << ")");
        return false;
    }
    token_end = data.find_first_of(Syntax, token_end + 1);
  }
  return true;
}

bool RCParser::ExtractObjectDetails(const string& data, vector<RCObject>& objects) {
  size_t scope_begin = data.find_first_of('{'),
         scope_end   = data.find_last_of('}');
  if(scope_begin == string::npos || scope_end == string::npos) {
    Debug("Invalid token " << data);
    return false;
  }

  string header = data.substr(0, scope_begin);
  size_t name_end = header.find_last_not_of(' ');
  if(name_end == string::npos) {
    Debug("Invalid header");
    return false;
  }

  RCObject object;
  object.header = header.substr(0, name_end + 1);
  string fieldData = data.substr(scope_begin + 1, scope_end - scope_begin - 1);
  if(!ExtractObjectFields(fieldData, object)) {
    return false;
  }
  objects.push_back(object);

  return true;
}

bool RCParser::ExtractObjectFields(const string& data, RCObject& object) {
  size_t token_begin = data.find_first_not_of(';'),
         token_end   = data.find_first_of(';', token_begin);

  while(token_begin != string::npos && token_end != string::npos) {
    string token = data.substr(token_begin, token_end - token_begin);

    token_begin = data.find_first_not_of(';', token_end);
    token_end   = data.find_first_of(';', token_begin);

    size_t actual_begin = token.find_first_not_of(Whitespace),
           actual_end   = token.find_last_not_of(Whitespace);
    if(actual_begin == string::npos || actual_end == string::npos) {
      Debug("Invalid field");
      return false;
    }

    RCField field;
    if(ExtractFieldDetails(token.substr(actual_begin, actual_end - actual_begin + 1), field)) {
      object.fields.push_back(field);
    } else {
      return false;
    }
  }
  return true;
}

bool RCParser::ExtractFieldDetails(const string& data, RCField& field) {
  size_t name_start = data.find_last_of(Whitespace);
  if(name_start == string::npos) {
    Debug("Failed to extract field name from " << data);
    return false;
  }

  field.name = data.substr(name_start + 1);
  string typeData = data.substr(0, name_start);
  size_t type_end = typeData.find_last_not_of(Whitespace);
  if(type_end == string::npos) {
    Debug("Failed to extract field type");
    return false;
  }
  field.type = typeData.substr(0, type_end + 1);
  return true;
}
