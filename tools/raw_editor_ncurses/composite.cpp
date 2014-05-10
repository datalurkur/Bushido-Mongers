#include "tools/raw_editor_ncurses/composite.h"
#include "tools/raw_editor_ncurses/common.h"

#include "ui/menu.h"
#include "ui/prompt.h"

void editCompositeLayers(ProtoCompositeBObject* object) {
  DynamicMenu layerMenu("Layers");
  layerMenu.addChoice("List Layers", [&]() {
    StaticMenu layerList("Behold, the layers", object->layers);
    string unused;
    layerList.getChoice(unused);
  });
  layerMenu.addChoice("Add Layer", [&]() {
    string layerName;
    if(!Prompt::Word("Enter the layer type:", layerName) || layerName.size() == 0) {
      Prompt::Popup("No layer given; aborting");
      return;
    }

    if(object->layers.size() == 0) {
      object->layers.push_back(layerName);
    } else {
      StaticMenu basePrompt("Which layer is this layer directly on top of?", object->layers);
      basePrompt.addChoice("(core layer)");

      string baseChoice;
      if(!basePrompt.getChoice(baseChoice)) { return; }

      if(baseChoice == "(core layer)") {
        object->layers.push_back(layerName);
        Prompt::Popup("New layer " + layerName + " is the core layer");
      } else {
        list<string>::iterator itr;
        for(itr = object->layers.begin(); itr != object->layers.end(); itr++) {
          if(*itr == baseChoice) {
            object->layers.insert(itr, layerName);
            Prompt::Popup("New layer " + layerName + " inserted directly above layer " + *itr);
            break;
          }
        }
      }
    }
  });
  layerMenu.addChoice("Remove Layer", [&]() {
    string layerName;
    if(!Prompt::Word("Layer name to delete:", layerName) || layerName.length() == 0) {
      Prompt::Popup("No layer given; aborting");
      return;
    }

    object->layers.remove(layerName);
  });
  layerMenu.addChoice("Reorder Layer", [&]() {
    // Get the layer that's going to be moved
    StaticMenu layerPrompt("Select the layer to move", object->layers);
    string layerName;
    if(!layerPrompt.getChoice(layerName)) { return; }

    // Prepare some iterators for the move
    list<string>::iterator p, i;
    for(i = object->layers.begin(); i != object->layers.end(); i++) {
      if(*i == layerName) { break; }
    }

    DynamicMenu directionPrompt("Where should the layer be moved?");
    directionPrompt.addChoice("Closer to the surface", [&]() {
      if(i == object->layers.begin()) {
        Prompt::Popup("Layer is already at the surface");
        return;
      }
      p = i;
      p--;
      object->layers.erase(i);
      object->layers.insert(p, *i);
    });
    directionPrompt.addChoice("Closer to the core", [&]() {
      p = i;
      p++;
      if(p == object->layers.end()) {
        Prompt::Popup("Layer is already at the core");
        return;
      }
      p++;
      object->layers.erase(i);
      object->layers.insert(p, *i);
    });
    directionPrompt.addChoice("To the surface", [&]() {
      object->layers.erase(i);
      object->layers.push_front(*i);
    });
    directionPrompt.addChoice("To the core", [&]() {
      object->layers.erase(i);
      object->layers.push_back(*i);
    });

    directionPrompt.act();
  });

  while(layerMenu.act()) {}
}

void editCompositeBObject(const string& name, ProtoCompositeBObject* object) {
  Info("Editing composite object " << name);

  DynamicMenu editMenu("Select an attribute to edit");
  editMenu.addChoice("Keywords", [&]() {
    editObjectKeywords(object);
  });
  editMenu.addChoice("Layers", [&]() {
    editCompositeLayers(object);
  });
}
