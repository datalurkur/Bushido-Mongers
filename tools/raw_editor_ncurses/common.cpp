#include "tools/raw_editor_ncurses/common.h"

#include "curseme/menu.h"
#include "curseme/input.h"

void editObjectKeywords(ProtoBObject* object) {
  vector<string> choices;

  Menu keywordMenu("Add or Remove Keywords");

  keywordMenu.addChoice("Add Keyword", [&]() {
    string keyword;
    Input::GetWord("Enter the new keyword:", keyword);

    keywordMenu.addChoice(keyword);

    object->keywords.push_back(keyword);
    object->keywords.unique();
  });

  for(string kw : object->keywords) { keywordMenu.addChoice(kw); }

  keywordMenu.setDefaultAction([&](string kw) {
    keywordMenu.removeChoice(kw);

    object->keywords.remove(kw);
  });

  keywordMenu.listen();
}
