#include "tools/raw_editor/common.h"

#include "interface/choice.h"
#include "interface/console.h"

void editObjectKeywords(ProtoBObject* object) {
  Choice keywordMenu;
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
      Choice keywordSelect(object->keywords);
      keywordSelect.getChoice(keyword, 3);
      object->keywords.remove(keyword);
    } break;
    }
  }
}
