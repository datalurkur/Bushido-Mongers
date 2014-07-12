#include "util/filesystem.h"
#include "util/log.h"

#include "resource/raw.h"
#include "game/atomicbobject.h"
#include "game/compositebobject.h"
#include "game/complexbobject.h"
#include "game/containerbobject.h"

#include "ui/prompt.h"
#include "ui/menu.h"

#include "tools/raw_editor_ncurses/complex.h"
#include "tools/raw_editor_ncurses/composite.h"
#include "tools/raw_editor_ncurses/common.h"

#include <list>
#include <fstream>
#include <sstream>

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

  // FIXME: sanitize input further
  // e.g. forcing certain characters into menus make the menu not display at all.
  // we probably don't want these special characters in filenames either...
  if(!Prompt::Word("Enter a raw filename:", name) || name.length() == 0) {
    Prompt::Popup("Invalid file name");
    return;
  }

  if(name.length() <= 4 || name.substr(name.length()-4) != ".raw") {
    name += ".raw";
  }

  list<string> existingFiles;
  getRawsList(dir, existingFiles);
  for(string file : existingFiles) {
    if(name == file) {
      Prompt::Popup("File already exists!");
      return;
    }
  }

  Raw emptyRaw;
  saveRaw(emptyRaw, dir, name);
}

void addObject(Raw& raw) {
  string objectName;
  // FIXME: sanitize input further
  if(!Prompt::Word("Enter a name for the new object: ", objectName) || objectName.length() == 0) {
    Prompt::Popup("Invalid name: too short");
    return;
  }

  DynamicMenu objectTypeMenu("Choose an object type");

  objectTypeMenu.addChoice("Atomic (single-material object)", [&]() {
    raw.addObject(objectName, (ProtoBObject*)new ProtoAtomicBObject(objectName));
  });
  objectTypeMenu.addChoice("Composite (layered object)", [&]() {
    raw.addObject(objectName, (ProtoBObject*)new ProtoCompositeBObject(objectName));
  });
  objectTypeMenu.addChoice("Complex (component objects connected in arbitrary ways)", [&]() {
    raw.addObject(objectName, (ProtoBObject*)new ProtoComplexBObject(objectName));
  });

  objectTypeMenu.act();
}

void editAtomicBObject(const string& name, ProtoAtomicBObject* object) {
  stringstream title;
  title << "Editing atomic object " << name;

  DynamicMenu editMenu(title.str());

  editMenu.addChoice("Keywords", [&object]() {
    editObjectKeywords(object);
  });
  editMenu.addChoice("Weight", [&]() {
    float newWeight;
    stringstream prompt;
    prompt << "Enter a new weight (currently " << object->weight << ")";
    if(!Prompt::Number<float>(prompt.str(), newWeight)) {
      Prompt::Popup("Invalid weight value entered");
    } else {
      object->weight = newWeight;
      Prompt::Popup("Weight of " + name + " set to " + object->weight);
    }
  });

  while(editMenu.act()) {}
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
  StaticMenu objectSelectMenu("Select An Object", objectNames);

  string objectName;
  while(objectSelectMenu.getChoice(objectName)) {
    editObject(raw, objectName);
  }
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

  DynamicMenu rawMenu("Editing " + name);

  rawMenu.addChoice("List Objects", [&raw]() {
    list<string> names;
    raw.getObjectNames(names);

    stringstream title;
    title << "Raw contains " << names.size() << " object" << ((names.size() == 1)? "" : "s");

    StaticMenu displayMenu(title.str(), names);
    // TODO - Is this supposed to do something, or just list names and then teardown?
    string unused;
    displayMenu.getChoice(unused);
  });

  rawMenu.addChoice("Add Object", [&raw]() {
    addObject(raw);
  });

  rawMenu.addChoice("Remove Object", [&raw]() {
    string objectName;
    if(!Prompt::Word("Enter object name to remove:", objectName) || objectName.length() == 0) {
      Prompt::Popup("Invalid object name");
    } else if(!raw.deleteObject(objectName)) {
      Prompt::Popup("No object " + objectName + " found in raw");
    }
  });

  rawMenu.addChoice("Edit Object", [&raw]() {
    if(raw.getNumObjects() != 0) { // avoid editing an undefined object
      selectAndEditObject(raw);
    } else {
      Prompt::Popup("No object selected!");
    }
  });

  rawMenu.addChoice("Save Changes", [&]() {
    saveRaw(raw, dir, name);
  });

  while(rawMenu.act()) {}
}

void selectAndEditRaw(const string& dir) {
  list<string> raws;

  if(!getRawsList(dir, raws)) {
    Error("Failed to load raws from " << dir);
    return;
  }

  StaticMenu rawChoice("Select raw", raws);
  string raw;
  while(rawChoice.getChoice(raw)) {
    editRaw(dir, raw);
  }
}

int main(int argc, char** argv) {
  Log::Setup();
  CurseMe::Setup();

  // Get the root directory to search for raws
  string root;
  if(argc < 2) {
    bool valid = false;
    while(!valid) {
      // FIXME: sanitize input further
      if(!Prompt::Word("Please specify a raw directory", root) || root.length() == 0) {
        Prompt::Popup("Invalid raw directory entry: too short");
      } else {
        valid = true;
      }
    }
  } else {
    root = argv[1];
  }

  mvprintw(0, 0, "Welcome to the raw editor");
  mvprintw(1, 0, "Hit <F1> to go back");
  mvprintw(2, 0, ("Searching for raws in " + root).c_str());

  DynamicMenu defaultMenu("Main Menu");

  defaultMenu.addChoice("Create New Raw", [root]() {
    createRaw(root);
  });
  defaultMenu.addChoice("Edit Existing Raw", [root]() {
    selectAndEditRaw(root);
  });

  while(defaultMenu.act()) {}

  CurseMe::Teardown();
  Log::Teardown();
  return 0;
}

#pragma message "This really needs to use signals to gracefully handle control-C"
