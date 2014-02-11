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

void saveRaw(Raw& raw, const string& dir, const string& name) {
  void* rawData;
  unsigned int size;
  if(!raw.pack(&rawData, size)) {
    Error("Failed to pack raw data");
    return;
  }

  if(!FileSystem::SaveFileData(FileSystem::JoinFilename(dir, name), rawData, size)) {
    Error("Failed to save raw data to " << name);
  }
  free(rawData);
}

void createRaw(const string& dir) {
  string name;
  Info("Enter a raw filename: ");
  cin >> name;

  if(name.substr(name.length()-4) != ".raw") {
    name += ".raw";
  }

  Raw emptyRaw;
  saveRaw(emptyRaw, dir, name);
}

void addObject(Raw& raw) {
  string objectName;
  Info("Enter a name for the new object:");
  cin >> objectName;

  Choice objectTypeMenu("Choose an object type");
  objectTypeMenu.addChoice("atomic");
  objectTypeMenu.addChoice("complex");

  int choice;
  if(!objectTypeMenu.getSelection(choice)) { return; }

  ProtoBObject* object;
  switch(choice) {
  case 0:
    object = (ProtoBObject*)new ProtoAtomicBObject();
    break;
  case 1:
    object = (ProtoBObject*)new ProtoComplexBObject();
  }

  raw.addObject(objectName, object);
}

void editAtomicBObject(const string& name, ProtoAtomicBObject* object) {
  Info("Editing atomic object " << name);
  Info("\tweight: " << object->weight);

  Choice editMenu("Select an attribute to edit");
  editMenu.addChoice("weight");

  int choice;
  while(editMenu.getSelection(choice)) {
    switch(choice) {
    case 0:
      Info("Enter a new weight (currently " << object->weight << ")");
      cin >> object->weight;
      Info("Weight of " << name << " set to " << object->weight);
      break;
    }
  }
}

void editComplexBObject(const string& name, ProtoComplexBObject* object) {
  Info("Editing complex object " << name);

  int choice;
  Choice editMenu("Select an attribute to edit");
  while(editMenu.getSelection(choice)) {
  }
}

void editObject(Raw& raw, const string& objectName) {
  ProtoBObject* object = raw.getObject(objectName);
  switch(object->type) {
  case AtomicType:
    editAtomicBObject(objectName, (ProtoAtomicBObject*)object);
    break;
  case ComplexType:
    editComplexBObject(objectName, (ProtoComplexBObject*)object);
    break;
  default:
    Error("Unhandled object type " << object->type);
    return;
  }
}

void selectAndEditObject(Raw& raw) {
  list<string> objectNames;
  raw.getObjectNames(objectNames);
  Choice objectSelectMenu(objectNames);

  string selection;
  if(!objectSelectMenu.getChoice(selection)) { return; }

  editObject(raw, selection);
}

void cloneObject(Raw& raw) {
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
  
  Choice rawMenu("Editing " + name);
  rawMenu.addChoice("List Objects");
  rawMenu.addChoice("Add Object");
  rawMenu.addChoice("Remove Object");
  rawMenu.addChoice("Edit Object");
  rawMenu.addChoice("Clone Object");
  rawMenu.addChoice("Save Changes");

  int choice;
  string objectName;
  while(rawMenu.getSelection(choice)) {
    switch(choice) {
      case 0: {
        list<string> names;
        raw.getObjectNames(names);
        Info("Raw contains " << names.size() << " objects");
        for(list<string>::iterator itr = names.begin(); itr != names.end(); itr++) {
          Info(*itr);
        }
      } break;
      case 1:
        addObject(raw);
        break;
      case 2:
        Info("Enter object name to remove:");
        cin >> objectName;
        if(!raw.deleteObject(objectName)) {
          Error("No object " << objectName << " found in raw");
        }
        break;
      case 3:
        selectAndEditObject(raw);
        break;
      case 4:
        cloneObject(raw);
        break;
      case 5:
        saveRaw(raw, dir, name);
        break;
    }
  }
}

void selectAndEditRaw(const string& dir) {
  list<string> raws;
  if(!getRawsList(dir, raws)) {
    Error("Failed to load raws from " << dir);
    return;
  }

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
      break;
    case 1:
      selectAndEditRaw(root);
      break;
    }
  }

  Log::Teardown();
  return 0;
}
