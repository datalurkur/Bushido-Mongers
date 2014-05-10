#include "tools/raw_editor_ncurses/common.h"

#include "ui/menu.h"
#include "ui/prompt.h"

void editObjectKeywords(ProtoBObject* object) {
  vector<string> choices;

  DynamicMenu keywordMenu("Add or Remove Keywords");

  keywordMenu.setDefaultAction([&](string st) {
    object->keywords.remove(st);
  });

  do {
    keywordMenu.clearChoices();

    keywordMenu.addChoice("Add Keyword", [&]() {
      string keyword;
      Prompt::Word("Enter the new keyword:", keyword);

      object->keywords.push_back(keyword);
      object->keywords.unique();
    });

    for(string st : object->keywords) { keywordMenu.addChoice(st); }
  } while(keywordMenu.act());
}
