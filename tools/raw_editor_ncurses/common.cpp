#include "tools/raw_editor_ncurses/common.h"

#include "curseme/menu.h"
#include "interface/console.h"

void editObjectKeywords(ProtoBObject* object) {
  Menu keywordMenu;
  keywordMenu.addChoice("List keywords");
  keywordMenu.addChoice("Add keyword");
  if(object->keywords.size() > 0) {
    keywordMenu.addChoice("Remove keyword");
  }
  unsigned int choice;
  string keyword;
  while(keywordMenu.getSelection(choice)) {
    switch(choice) {
    case 0:
      for(string kw : object->keywords) { Info(kw); }
      break;
    case 1: {
      Info("Enter the keyword to add:");
      Console::GetWordInput(keyword);
      object->keywords.push_back(keyword);
      object->keywords.unique();
    } break;
    case 2: {
      Menu keywordSelect(object->keywords);
      keywordSelect.getChoice(keyword);
      object->keywords.remove(keyword);
    } break;
    }
  }
}
