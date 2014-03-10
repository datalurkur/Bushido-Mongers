#include "tools/raw_editor_ncurses/complex.h"
#include "tools/raw_editor_ncurses/common.h"

#include "curseme/menu.h"
#include "interface/console.h"

void editComplexBObject(const string& name, ProtoComplexBObject* object) {
  Info("Editing complex object " << name);

  unsigned int choice;
  Menu editMenu("Select an attribute to edit");
  editMenu.addChoice("Keywords");
  while(editMenu.getSelection(choice)) {
    switch(choice) {
    case 0:
      editObjectKeywords(object);
      break;
    }
  }
}

