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
    case 0:
      Input::GetWord("Enter the new keyword:", keyword);
      keywordMenu.addChoice(keyword);
      object->keywords.push_back(keyword);
      object->keywords.unique();
    break;
    default:
      object->keywords.remove(choices[choice - 1]);

      choices.erase(choices.begin() + choice - 1);
      keywordMenu = Menu(choices);
      keywordMenu.setTitle("Add or Remove Keywords");
      break;
    } // finish outer switch
  } // finish outer while
}
