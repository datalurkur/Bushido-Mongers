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

  Menu objectTypeMenu("Choose an object type");
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
  stringstream title;
  title << "Editing atomic object " << name << " (weight " << object->weight << ")";
  Menu editMenu(title.str());
  editMenu.addChoice("Keywords");
  editMenu.addChoice("Weight");

  unsigned int choice;
  while(editMenu.getSelection(choice)) {
    switch(choice) {
      case 0:
        editObjectKeywords(object);
        break;
      case 1:
        float newWeight;
        stringstream prompt;
        prompt << "Enter a new weight (currently " << object->weight << ")";
        if(!Input::GetNumber<float>(prompt.str(), newWeight)) {
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

  Menu rawMenu(list<string>({"List Objects", "Add Object", "Remove Object", "Edit Object", "Save Changes"}));
  rawMenu.setTitle("Editing " + name);

  unsigned int choice;
  string objectName;
  while(rawMenu.getSelection(choice)) {
    switch(choice) {
    case 0: {

      list<string> names;
      raw.getObjectNames(names);

      stringstream title;
      title << "Raw contains " << names.size() << " object" << ((names.size() == 1)? "" : "s");

      Menu displayMenu(names);
      displayMenu.setTitle(title.str());
      displayMenu.getSelection(choice);
    } break;
    case 1:
      addObject(raw);
      break;
    case 2:
      Input::GetWord("Enter object name to remove:", objectName);
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

  Info(raws.front());
  Menu rawChoice(raws);
  rawChoice.setTitle("Select raw");

  string choice;
  if(rawChoice.getChoice(choice)) {
    editRaw(dir, choice);
  }
}

int main(int argc, char** argv) {
  Log::Setup();
  CurseMeSetup();

  // Get the root directory to search for raws
  string root;
  if(argc < 2) {
    Input::GetWord("Please specify a raw directory", root);
  } else {
    root = argv[1];
  }

  mvprintw(0, 0, "Welcome to the raw editor");
  mvprintw(1, 0, "Hit <F1> to go back");
  mvprintw(2, 0, ("Searching for raws in " + root).c_str());

  Menu defaultMenu("Main Menu");
  defaultMenu.addChoice("Create New Raw");
  defaultMenu.addChoice("Edit Existing Raw");

  string currentRaw;
  unsigned int choice;
  while(defaultMenu.getSelection(choice)) {
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
