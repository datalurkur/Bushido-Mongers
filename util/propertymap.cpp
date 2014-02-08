#include "util/propertymap.h"
#include "util/convert.h"
#include "util/log.h"
#include "util/stringhelper.h"

#include <iostream>
#include <fstream>
#include <list>

PropertyMap::PropertyMap() {
}

bool PropertyMap::loadProperties(const char* data) {
  list<string> lines;
  TokenizeString(data, "\n", lines);

  bool ret = true;
  for(list<string>::iterator itr = lines.begin(); itr != lines.end(); itr++) {
    ret = ret && parseProperty(*itr);
  }
  return ret;
}

bool PropertyMap::parseProperty(const string& line) {
  size_t firstSpace, secondSpace;
  string type, key, value;

  firstSpace = line.find(' ');
  if(firstSpace == string::npos) {
    Error("Start of key not found on line '" << line << "'");
    return false;
  }
  type = line.substr(0, firstSpace);

  secondSpace = line.find(' ', firstSpace + 1);
  if(secondSpace == string::npos) {
    Error("Start of value not found in substring '" << line.substr(firstSpace + 1) << "'");
    return false;
  }
  key = line.substr(firstSpace + 1, (secondSpace - firstSpace - 1));
  value = line.substr(secondSpace);

  switch(type[0]) {
  case 'i':
    _intProps[key] = atoi(value.c_str());
    return true;
  case 'f':
    _floatProps[key] = atof(value.c_str());
    return true;
  case 'b':
    _boolProps[key] = (value == "true") ? true : false;
    return true;
  case 's':
    _stringProps[key] = value;
    return true;
  default:
    Error("Unknown property type " << type);
    return false;
  }
}

template <>
bool PropertyMap::getProperty<bool>(const string& propName, bool& value) const {
  map<string, bool>::const_iterator itr = _boolProps.find(propName);
  if(itr == _boolProps.end()) {
    return false;
  } else {
    value = itr->second;
    return true;
  }
}

template <>
bool PropertyMap::getProperty<int>(const string& propName, int& value) const {
  map<string, int>::const_iterator itr = _intProps.find(propName);
  if(itr == _intProps.end()) {
    return false;
  } else {
    value = itr->second;
    return true;
  }
}

template <>
bool PropertyMap::getProperty<float>(const string& propName, float& value) const {
  map<string, float>::const_iterator itr = _floatProps.find(propName);
  if(itr == _floatProps.end()) {
    return false;
  } else {
    value = itr->second;
    return true;
  }
}

template <>
bool PropertyMap::getProperty<string>(const string& propName, string& value) const {
  map<string, string>::const_iterator itr = _stringProps.find(propName);
  if(itr == _stringProps.end()) {
    return false;
  } else {
    value = itr->second;
    return true;
  }
}
