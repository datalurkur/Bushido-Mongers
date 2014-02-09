#include "util/filesystem.h"
#include "util/log.h"

#include "game/complexbobject.h"
#include "game/atomicbobject.h"

#include "interface/choice.h"

#include "resource/raw.h"

#include <list>
#include <fstream>

using namespace std;

bool getRawsList(const string& dir, list<string> &raws) {
  list<string> files;
  FileSystem::GetDirectoryContents(dir, files);
  list<string>::iterator itr;
  for(itr = files.begin(); itr != files.end(); itr++) {
    if(itr->length() <= 4) { continue; }
    if(itr->substr(itr->length() - 4) == ".raw") {
      raws.push_back(*itr);
    }
  }
  return true;
}

void createRaw(const string& dir) {
  string name;
  Info("Create a raw filename: ");
  cin >> name;

  Raw emptyRaw;
  void* rawData;
  unsigned int size;
  emptyRaw.pack(&rawData, size);

  if(!FileSystem::SaveFileData(FileSystem::JoinFilename(dir, name), rawData, size)) {
    Error("Failed to save raw data to " << name);
  }

  free(rawData);
}

void addObject(Raw& raw) {
}

void editObject(Raw& raw) {
}

void editRaw(const string& dir, const string& name) {
  void* fileData;
  unsigned int fileSize;
  fileSize = FileSystem::GetFileData(FileSystem::JoinFilename(dir, name), &fileData);

  if(fileSize == 0) {
    Error("Failed to read data from " << name);
    return;
  }

  Raw raw;
  raw.unpack(fileData, fileSize);
  free(fileData);
  
  list<string> names;
  raw.getObjectNames(names);

  Choice rawMenu;
  rawMenu.addChoice("List Objects");
  rawMenu.addChoice("Add Object");
  rawMenu.addChoice("Remove Object");
  rawMenu.addChoice("Edit Object");
  rawMenu.addChoice("Clone Object");

  int choice;
  string objectName;
  while(rawMenu.getSelection(choice)) {
    switch(choice) {
      case 0:
        for(list<string>::iterator itr = names.begin(); itr != names.end(); itr++) { Info(*itr); }
        break;
      case 1:
        addObject(raw);
        break;
      case 2:
        Info("Enter object name to remove:");
        cin >> objectName;
        break;
      case 3:
        editObject(raw);
        break;
      case 4:
        break;
    }
  }
}

void selectAndEditRaw(const string& dir, const list<string>& raws) {
  Choice rawChoice(raws);
  string choice;
  if(rawChoice.getChoice(choice)) {
    editRaw(dir, choice);
  }
}

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

  list<string> raws;
  if(!getRawsList(root, raws)) {
    Error("Failed to load raws from " << root);
    Log::Teardown();
    return 1;
  }

  Choice defaultMenu;
  defaultMenu.addChoice("Create New Raw");
  defaultMenu.addChoice("Edit Existing Raw");

  string currentRaw;
  bool running = true;
  int choice;
  while(running && defaultMenu.getSelection(choice)) {
    switch(choice) {
    case 0:
      createRaw(root);
      if(!getRawsList(root, raws)) {
        Error("Failed to reload raws");
        running = false;
      }
      break;
    case 1:
      selectAndEditRaw(root, raws);
      break;
    }
  }

  Log::Teardown();
  return 0;
}
