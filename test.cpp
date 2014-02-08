#include "util/propertymap.h"
#include "util/log.h"
#include "util/filesystem.h"

#include <stdio.h>

int main() {
  bool b;
  int i;
  float f;
  string s;

  Log::Setup();
  Info("Logging set up");

  char* plistData;

  if(!FileSystem::GetFileData("test_plist.plist", &plistData)) {
    Error("Failed to read test_plist.plist");
  }

  PropertyMap plist;
  if(!plist.loadProperties(plistData)) {
    Error("Failed to parse test_plist.plist");
  }

  if(plist.getProperty<bool>("is_this_thing_on?", b)) {
    Info("is_this_thing_on? : " << b);
  }
  if(plist.getProperty<int>("test_int", i)) {
    Info("int_prop : " << i);
  }
  if(plist.getProperty<float>("pi", f)) {
    Info("pi : " << f);
  }
  if(plist.getProperty<string>("test_string", s)) {
    Info("string_prop : " << s);
  }

  Log::Teardown();

  return 0;
}
