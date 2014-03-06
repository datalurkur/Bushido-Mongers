#include "tools/raw_editor/complex.h"
#include "tools/raw_editor/common.h"

#include "interface/choice.h"
#include "interface/console.h"

void editComplexBObject(const string& name, ProtoComplexBObject* object) {
  Info("Editing complex object " << name);

  unsigned int choice;
  Choice editMenu("Select an attribute to edit");
  editMenu.addChoice("Keywords");
  while(editMenu.getSelection(choice)) {
    switch(choice) {
    case 0:
      editObjectKeywords(object);
      break;
    }
  }
}

