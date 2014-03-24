#include "tools/raw_editor_ncurses/common.h"

#include "curseme/menu.h"
#include "curseme/input.h"

void editObjectKeywords(ProtoBObject* object) {
  vector<string> choices;
  choices.push_back("Add Keyword");
  for(string kw : object->keywords) { choices.push_back(kw); }

  Menu keywordMenu(choices);
  keywordMenu.setTitle("Add or Remove Keywords");

  unsigned int choice;
  string keyword;
  while(keywordMenu.getSelection(choice)) {
    switch(choice) {
    case 0: {
      Input::GetWord("Enter the new keyword:", keyword);
      object->keywords.push_back(keyword);
      object->keywords.unique();
    } break;
    default:
      keyword = choices[choice - 1];

      Menu EditRemoveMenu(keyword);
      EditRemoveMenu.addChoice("Edit");
      EditRemoveMenu.addChoice("Remove");

      while(EditRemoveMenu.getSelection(choice)) {
        switch(choice) {
        case 0:
        case 1:
          object->keywords.remove(keyword);
          break;
        }
      }
    } // finish outer switch
  } // finish outer while
}
