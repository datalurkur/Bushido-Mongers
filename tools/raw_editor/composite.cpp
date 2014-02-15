#include "tools/raw_editor/composite.h"
#include "tools/raw_editor/common.h"

#include "interface/choice.h"
#include "interface/console.h"

void editCompositeLayers(ProtoCompositeBObject* object) {
  Choice layerMenu;
  layerMenu.addChoice("List Layers");
  layerMenu.addChoice("Add Layer");
  layerMenu.addChoice("Remove Layer");
  layerMenu.addChoice("Reorder Layer");

  unsigned int choice;
  while(layerMenu.getSelection(choice)) {
    switch(choice) {
    case 0:
      for(string layerName : object->layers) { Info(layerName); }
      break;
    case 1: {
      string layerName;
      Info("Enter a name for the layer:");
      Console::GetWordInput(layerName);
      if(object->layers.size() == 0) {
        object->layers.push_back(layerName);
      } else {
        Info("Which layer is this layer directly on top of?");
        Choice basePrompt(object->layers);
        basePrompt.addChoice("(core layer)");
        string baseChoice;
        if(!basePrompt.getChoice(baseChoice)) {
          Info("Layer insertion aborted");
          break;
        }
        if(baseChoice == "(core layer)") {
          object->layers.push_back(layerName);
          Info("New layer " << layerName << " is the core layer");
        } else {
          list<string>::iterator itr;
          for(itr = object->layers.begin(); itr != object->layers.end() && *itr != baseChoice; itr++) {}
          object->layers.insert(itr, layerName);
          Info("New layer " << layerName << " inserted directly above layer " << *itr);
        }
      }
    } break;
    case 2: {
      string layerName;
      Console::GetWordInput(layerName);
      object->layers.remove(layerName);
    } break;
    case 3: {
      Info("Select the layer to move");
      Choice layerPrompt(object->layers);
      string layerName;
      if(!layerPrompt.getChoice(layerName)) { break; }
      Choice directionPrompt("Where should the layer be moved?");
      directionPrompt.addChoice("Closer to the surface");
      directionPrompt.addChoice("Closer to the core");
      directionPrompt.addChoice("To the surface");
      directionPrompt.addChoice("To the core");
      unsigned int dirChoice;
      if(!directionPrompt.getSelection(dirChoice)) { break; }
      list<string>::iterator p, i;
      for(i = object->layers.begin(); i != object->layers.end(); i++) {
        if(*i == layerName) { break; }
      }
      switch(dirChoice) {
      case 0:
        if(i == object->layers.begin()) {
          Info("Layer is already at the surface");
          break;
        }
        p = i;
        p--;
        object->layers.erase(i);
        object->layers.insert(p, *i);
        break;
      case 1:
        p = i;
        p++;
        if(p == object->layers.end()) {
          Info("Layer is already at the core");
          break;
        }
        p++;
        object->layers.erase(i);
        object->layers.insert(p, *i);
        break;
      case 2:
        object->layers.erase(i);
        object->layers.push_front(*i);
        break;
      case 3:
        object->layers.erase(i);
        object->layers.push_back(*i);
        break;
      }
    } break;
    }
  }
}

void editCompositeBObject(const string& name, ProtoCompositeBObject* object) {
  Info("Editing composite object " << name);

  unsigned int choice;
  Choice editMenu("Select an attribute to edit");
  editMenu.addChoice("Keywords");
  editMenu.addChoice("Layers");
  while(editMenu.getSelection(choice)) {
    switch(choice) {
    case 0:
      editObjectKeywords(object);
      break;
    case 1:
      editCompositeLayers(object);
      break;
    }
  }
}
