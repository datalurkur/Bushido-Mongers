#include "tools/raw_editor_ncurses/complex.h"
#include "tools/raw_editor_ncurses/common.h"

#include "curseme/menu.h"
#include "curseme/input.h"

#include <sstream>

void editComplexBObject(const string& name, ProtoComplexBObject* object) {
  Menu editMenu("Select an attribute of complex object " + name + " to edit");

  editMenu.addChoice("Keywords", [&object]() {
    editObjectKeywords(object);
  });

  editMenu.addChoice("Components", [&]() {
    editComplexComponents(name, object);
  });

  editMenu.addChoice("Connections", [&]() {
    editComplexConnections(name, object);
  });

  editMenu.listen();
}

void editComplexComponents(const string& name, ProtoComplexBObject* object) {
  ostringstream ss;
  ss << "Edit components of " << name;
  Menu editComponents(ss.str(), [&](Menu* editComponents) {

    editComponents->addChoice("Add Component", [&object]() {
      string nickname, type;

      Input::GetWord("Enter name for part (e.g. left arm):", nickname);

      if(nickname.length() == 0) {
        Popup("No nickname given!");
      }

      if(object->hasComponent(nickname)) {
        Popup("Nickname already exists!");
      }

      Input::GetWord("Enter component type:", type); // TODO - convert to selection from list of types

      if(type.length() == 0) { // FIXME - || !raws.objectNames.include?(type)
        Popup("Invalid component type!");
      }

      object->addComponent(nickname, type);
    });

    set<string> nicknames;
    object->getComponents(nicknames);
    for(auto nickname : nicknames) {
      editComponents->addChoice(nickname);
    }

    editComponents->setDefaultAction([&](StringPair nickname) {
      object->remComponent(nickname.first);
    });
  });

  editComponents.listen();
}

void editComplexConnections(const string& name, ProtoComplexBObject* object) {
  Menu editConnections("Connections of " + name, [&](Menu* editConnections) {
    editConnections->addChoice("Add Connection", [&]() {
      string first, second;

      Input::GetWord("Enter first nickname:", first); // TODO - convert to selection from list of types

      Debug(first);

      if(first.length() == 0) {
        Popup("No nickname given!");
      }

      Debug(first);

      if(!object->hasComponent(first)) {
        Popup("Nickname " + first + " does not exist");
      }

      Debug(first);

      Input::GetWord("Enter second nickname:", second);

      if(second.length() == 0) { // || !raws.objectNames.include?(type)
        Popup("No nickname given!");
      }

      if(!object->hasComponent(second)) {
        Popup("Nickname " + second + " does not exist");
      }

      object->addConnection(make_pair(first, second));
    });

    set<StringPair> connections;
    object->getConnections(connections);

    for(auto connection : connections) {
      editConnections->addChoice(connection);
    }

    editConnections->setDefaultAction([&](StringPair choice) {
      object->remConnection(choice);
      editConnections->removeChoice(choice);
    });
  });

  editConnections.listen();
}