#include "util/filesystem.h"
#include "util/log.h"

#include <list>

using namespace std;

int main(int argc, char** argv) {
  // Set up logging
  Log::Setup();

  // Get the root directory to search for raws
  if(argc < 2) {
    Error("Please specify a raw directory");
    Log::Teardown();
    return 1;
  }

  string root = argv[1];
  Info("Searching for raws in " << root);

  // Get a list of all of the raw files
  list<string> raws;
  FileSystem::GetDirectoryContents(root, raws);

  list<string>::iterator itr;
  for(itr = raws.begin(); itr != raws.end(); itr++) {
    Info("Found raw file " << *itr);
  }
  
  Log::Teardown();
  return 0;
}
