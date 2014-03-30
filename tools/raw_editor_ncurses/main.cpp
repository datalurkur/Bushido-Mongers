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
  Input::GetWord("Enter a raw filename: ", name);

  // FIXME: sanitize input further
  // e.g. forcing certain characters into menus make the menu not display at all.
  // we probably don't want these special characters in filenames either...
  if(name.length() == 0) {
    Popup("Invalid file name");
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
  Input::GetWord("Enter a name for the new object: ", objectName);
  // FIXME: sanitize input further
  if(objectName.length() == 0) {
    Popup("Invalid name: too short");
    return;
  }

  Menu objectTypeMenu("Choose an object type");
  objectTypeMenu.setEndOnSelection(true);

  objectTypeMenu.addChoice("Atomic (single-material object)", [&]() {
    raw.addObject(objectName, (ProtoBObject*)new ProtoAtomicBObject());
  });
  objectTypeMenu.addChoice("Composite (layered object)", [&]() {
    raw.addObject(objectName, (ProtoBObject*)new ProtoCompositeBObject());
  });
  objectTypeMenu.addChoice("Complex (component objects connected in arbitrary ways)", [&]() {
    raw.addObject(objectName, (ProtoBObject*)new ProtoCompositeBObject());
  });

  objectTypeMenu.listen();
}

void editAtomicBObject(const string& name, ProtoAtomicBObject* object) {
  stringstream title;
  title << "Editing atomic object " << name << " (weight " << object->weight << ")";

  Menu editMenu(title.str());

  editMenu.addChoice("Keywords", [&object]() {
    editObjectKeywords(object);
  });
  editMenu.addChoice("Weight", [&]() {
    float newWeight;
    stringstream prompt;
    prompt << "Enter a new weight (currently " << object->weight << ")";
    if(!Input::GetNumber<float>(prompt.str(), newWeight)) {
      Popup("Invalid weight value entered");
    } else {
      object->weight = newWeight;
      Popup("Weight of " << name << " set to " << object->weight);
    }
  });

  editMenu.listen();
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

  objectSelectMenu.setDefaultAction([&raw](string objectName) {
    editObject(raw, objectName);
  });

  objectSelectMenu.listen();
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

  rawMenu.addChoice("List Objects", [&raw]() {
    list<string> names;
    raw.getObjectNames(names);

    stringstream title;
    title << "Raw contains " << names.size() << " object" << ((names.size() == 1)? "" : "s");

    Menu displayMenu(names);
    displayMenu.setTitle(title.str());
    displayMenu.listen();
  });

  rawMenu.addChoice("Add Object", [&raw]() {
    addObject(raw);
  });

  rawMenu.addChoice("Remove Object", [&raw]() {
    string objectName;
    Input::GetWord("Enter object name to remove:", objectName);
    if(!raw.deleteObject(objectName)) {
      Popup("No object " << objectName << " found in raw");
    }
  });

  rawMenu.addChoice("Edit Object", [&raw]() {
    if(raw.getNumObjects() != 0) { // avoid editing an undefined object
      selectAndEditObject(raw);
    } else {
      Popup("No object selected!");
    }
  });

  rawMenu.addChoice("Save Changes", [&raw, dir, name]() {
    saveRaw(raw, dir, name);
  });

  rawMenu.listen();
}

void selectAndEditRaw(const string& dir) {
  list<string> raws;

  if(!getRawsList(dir, raws)) {
    Error("Failed to load raws from " << dir);
    return;
  }

  Menu rawChoice(raws);
  rawChoice.setTitle("Select raw");
  rawChoice.setDefaultAction([dir](string raw) {
    editRaw(dir, raw);
  });

  rawChoice.listen();
}

int main(int argc, char** argv) {
  Log::Setup();
  CurseMeSetup();

  // Get the root directory to search for raws
  string root;
  if(argc < 2) {
    bool valid = false;
    while(!valid) {
      Input::GetWord("Please specify a raw directory", root);
      // FIXME: sanitize input further
      if(root.length() == 0) {
        Popup("Invalid raw directory entry: too short");
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

  Menu defaultMenu("Main Menu");

  defaultMenu.addChoice("Create New Raw", [root]() {
    createRaw(root);
  });
  defaultMenu.addChoice("Edit Existing Raw", [root]() {
    selectAndEditRaw(root);
  });

  defaultMenu.listen();

  CurseMeTeardown();
  Log::Teardown();
  return 0;
}
