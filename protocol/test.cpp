#include "protocol/rcparser.h"

#include <fstream>

using namespace std;

int main() {
  ifstream eventData;
  eventData.open("protocol/events.rc");
  string str((istreambuf_iterator<char>(eventData)), istreambuf_iterator<char>());

  vector<RCObject> objects;
  RCParser::ExtractObjects(str, objects);
  return 0;
}
