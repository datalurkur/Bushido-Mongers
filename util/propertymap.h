#ifndef PROPERTY_MAP_H
#define PROPERTY_MAP_H

#include <map>
#include <string>

using namespace std;

class PropertyMap {
public:
  PropertyMap();

  bool loadProperties(const char* data);
  bool dumpProperties(char** data, int& size);

  template <typename T>
  bool getProperty(const string& propName, T& value) const;

  template <typename T>
  bool addProperty(const string& propName, T& value);

private:
  bool parseProperty(const string& line);

private:
  map<string, bool> _boolProps;
  map<string, int> _intProps;
  map<string, float> _floatProps;
  map<string, string> _stringProps;
};

#endif
