#include "tools/raw_editor_ncurses/complex.h"
#include "tools/raw_editor_ncurses/common.h"

#include "util/structure.h"

#include "ui/menu.h"
#include "ui/prompt.h"

#include <sstream>

void editComplexBObject(const string& name, ProtoComplexBObject* object) {
  DynamicMenu editMenu("Select an attribute of complex object " + name + " to edit");

  editMenu.addChoice("Keywords", [&object]() {
    editObjectKeywords(object);
  });

  editMenu.addChoice("Components", [&]() {
    editComplexComponents(name, object);
  });

  editMenu.addChoice("Connections", [&]() {
    editComplexConnections(name, object);
  });

  while(editMenu.act()) {}
}

void editComplexComponents(const string& name, ProtoComplexBObject* object) {
  DynamicMenu editComponents("Edit components of " + name);

  do {
    editComponents.clearChoices();

    editComponents.addChoice("Add Component", [&object]() {
      string nickname, type;

      Prompt::Word("Enter name for part (e.g. left arm):", nickname);

      if(nickname.length() == 0) {
        Prompt::Popup("No nickname given!");
      }

      if(object->hasComponent(nickname)) {
        Prompt::Popup("Nickname already exists!");
      }

      Prompt::Word("Enter component type:", type); // TODO - convert to selection from list of types

      if(type.length() == 0) { // FIXME - || !raws.objectNames.include?(type)
        Prompt::Popup("Invalid component type!");
      }

      object->addComponent(nickname, type);
    });

    for(auto component : object->components) {
      editComponents.addChoice(component.first);
    }

    editComponents.setDefaultAction([&](string nickname) {
      object->remComponent(nickname);
    });
  } while(editComponents.act());
}

void editComplexConnections(const string& name, ProtoComplexBObject* object) {
  set<string> components;
  for(auto component : object->components) {
    components.insert(component.first);
  }

  DynamicMenu editConnections("Connections of " + name);

  editConnections.addChoice("Add Connection", [&]() {
    string first, second;

    StaticMenu selectFirst("Select first component", components);
    if(!selectFirst.getChoice(first)) { return; }
    StaticMenu selectSecond("Select second component", components - set<string>({first}));
    if(!selectSecond.getChoice(second)) { return; }

    object->addConnection(first, second);
  });

  editConnections.addChoice("Remove Connection", [&]() {
    StaticMenu selectFirst("Select first connected component");
    for(auto connectionData : object->connections) {
      if(connectionData.second.size() > 0) { selectFirst.addChoice(connectionData.first); }
    }

    string first, second;
    if(!selectFirst.getChoice(first)) { return; }

    auto connectionData = object->connections.find(first);
    if(connectionData == object->connections.end()) {
      Error(L"Bad connection data");
      return;
    }
    StaticMenu selectSecond("Select second connected component", connectionData->second);
    if(!selectSecond.getChoice(second)) { return; }

    object->remConnection(first, second);
  });

  while(editConnections.act()) {}
}
