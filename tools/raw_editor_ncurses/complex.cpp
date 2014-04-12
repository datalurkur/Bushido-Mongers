#include "tools/raw_editor_ncurses/complex.h"
#include "tools/raw_editor_ncurses/common.h"

#include "curseme/menu.h"
#include "curseme/input.h"

#include <sstream>

void editComplexBObject(const string& name, ProtoComplexBObject* object) {
  unsigned int choice;
  Menu editMenu("Select an attribute of complex object " + name + " to edit");

  editMenu.addChoice("Keywords", [&object]() {
    editObjectKeywords(object);
  });

  editMenu.addChoice("Components", [&]() {
    editComplexComponents(name, object);
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

      /*
      if(object.nicknames.include?(nickname)) {
        Popup("Nickname already exists!");
      }
      */

      Input::GetWord("Enter component type:", type); // TODO - convert to selection from list of types

      if(type.length() == 0) { // || !raws.objectNames.include?(type)
        Popup("Invalid component type!");
      }

      object->addComponent(nickname, type);
    });

    set<string> nicknames;
    object->getComponents(nicknames);
    for(auto nickname : nicknames) {
      editComponents->addChoice(nickname);
    }

    editComponents->setDefaultAction([&](string nickname) {
      ostringstream oss;
      oss << "Editing " << name << " component \"" << nickname << "\"";

      Menu editComponent(oss.str());

      editComponent.addChoice("Add Connection", [&]() {
        string connection;
        Input::GetWord("Enter nickname of part to connect to " + nickname + ":", connection);  // TODO - convert to selection from list of nicknames

        if((find(nicknames.begin(), nicknames.end(), nickname)) != nicknames.end()) {
          object->addConnection(nickname, connection);
        } else {
          // TODO - it makes sense to be able to create new components here
          //        in the event the nickname doesn't exist.
          Popup("Nickname does not exist");
        }
      });

      set<string> connections;
      object->getConnectionsFromComponent(nickname, connections);
      for(auto cnx : connections) { editComponents->addChoice(cnx); }

      editComponent.setDefaultAction([&](string cxn) {
        object->remConnection(nickname, cxn);
      });

      editComponent.listen();
    });
  });

  editComponents.listen();
}