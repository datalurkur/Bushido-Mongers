#include "util/filesystem.h"
#include "util/log.h"

#include "game/atomicbobject.h"

#include "interface/choice.h"
#include "interface/console.h"

#include "resource/raw.h"

#include "curseme/curseme.h"
#include "curseme/input.h"
#include "curseme/menu.h"

#include "tools/raw_editor_ncurses/complex.h"
#include "tools/raw_editor_ncurses/composite.h"
#include "tools/raw_editor_ncurses/common.h"

#include <list>
#include <fstream>

// sleep
#if SYS_PLATFORM == PLATFORM_WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif

using namespace std;

bool getRawsList(const string& dir, list<string> &raws) {
  list<string> files;
  FileSystem::GetDirectoryContents(dir, files);
  for(string file : files) {
    if(file.length() <= 4) { continue; }
    if(file.substr(file.length() - 4) == ".raw") {
      raws.push_back(file);
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
  Input::GetWord(name);

  if(name.length() == 0) {
    Error("Invalid file name");
    return;
  }

  if(name.length() <= 4 || name.substr(name.length()-4) != ".raw") {
    name += ".raw";
  }

  Raw emptyRaw;
  saveRaw(emptyRaw, dir, name);
}

void addObject(Raw& raw) {
  string objectName;
  Info("Enter a name for the new object: ");
  Input::GetWord(objectName);

  Menu  objectTypeMenu("Choose an object type");
  objectTypeMenu.addChoice("Atomic (single-material object)");
  objectTypeMenu.addChoice("Composite (layered object)");
  objectTypeMenu.addChoice("Complex (component objects connected in arbitrary ways)");

  unsigned int choice;
  if(!objectTypeMenu.getSelection(choice)) { return; }

  ProtoBObject* object;
  switch(choice) {
  case 0:
    object = (ProtoBObject*)new ProtoAtomicBObject();
    break;
  case 1:
    object = (ProtoBObject*)new ProtoCompositeBObject();
    break;
  case 2:
    object = (ProtoBObject*)new ProtoComplexBObject();
    break;
  }

  raw.addObject(objectName, object);
}


void editAtomicBObject(const string& name, ProtoAtomicBObject* object) {
  Info("Editing atomic object " << name);
  Info("\tweight: " << object->weight);

  Menu editMenu("Select an attribute to edit");
  editMenu.addChoice("Keywords");
  editMenu.addChoice("Weight");

  unsigned int choice;
  while(editMenu.getSelection(choice)) {
    editMenu.teardown();
    switch(choice) {
    case 0:
      editObjectKeywords(object);
      break;
    case 1:
      Info("Enter a new weight (currently " << object->weight << ")");
      float newWeight;
      if(!Input::GetNumber<float>(newWeight)) {
        Error("Invalid weight value entered");
        break;
      }
      object->weight = newWeight;
      Info("Weight of " << name << " set to " << object->weight);
      break;
    }
  }
}

void editObject(Raw& raw, const string& objectName) {
  ProtoBObject* object = raw.getObject(objectName);
  switch(object->type) {
  case AtomicType:
    editAtomicBObject(objectName, (ProtoAtomicBObject*)object);
    break;
  case CompositeType:
    editCompositeBObject(objectName, (ProtoCompositeBObject*)object);
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
  Menu objectSelectMenu(objectNames);

  string selection;
  if(!objectSelectMenu.getChoice(selection)) { return; }

  editObject(raw, selection);
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
  
  Menu rawMenu("Editing " + name);
  rawMenu.addChoice("List Objects");
  rawMenu.addChoice("Add Object");
  rawMenu.addChoice("Remove Object");
  rawMenu.addChoice("Edit Object");
  rawMenu.addChoice("Save Changes");

  unsigned int choice;
  string objectName;
  while(rawMenu.getSelection(choice)) {
    switch(choice) {
    case 0: {
      list<string> names;
      raw.getObjectNames(names);
      Info("Raw contains " << names.size() << " objects");
      for(string name : names) { Info(name); }
    } break;
    case 1:
      addObject(raw);
      break;
    case 2:
      Info("Enter object name to remove:");
      Input::GetWord(objectName);
      if(!raw.deleteObject(objectName)) {
        Error("No object " << objectName << " found in raw");
      }
      break;
    case 3:
      selectAndEditObject(raw);
      break;
    case 4:
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

  Menu rawChoice(raws);
  string choice;
  if(rawChoice.getChoice(choice)) {
    rawChoice.teardown();
    editRaw(dir, choice);
  }
}

int main(int argc, char** argv) {
  Log::Setup();
  CurseMeSetup();
  mvprintw(LINES - 6, 2, "Welcome to the raw editor");

  // Get the root directory to search for raws
  if(argc < 2) {
    Error("Please specify a raw directory");
    sleep(1);
    CurseMeTeardown();
    Log::Teardown();
    return 1;
  }
  string root = argv[1];
  Info("Searching for raws in " << root);

  Menu defaultMenu("Main Menu");
  defaultMenu.addChoice("Create New Raw");
  defaultMenu.addChoice("Edit Existing Raw");

  string currentRaw;
  bool running = true;
  unsigned int choice;
  while(running && defaultMenu.getSelection(choice)) {
    defaultMenu.teardown();
    switch(choice) {
    case 0:
      createRaw(root);
      break;
    case 1:
      selectAndEditRaw(root);
      break;
    }
  }

  CurseMeTeardown();

  Log::Teardown();
  return 0;
}
