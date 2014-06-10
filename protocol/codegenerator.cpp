#include "protocol/codegenerator.h"
#include "util/filesystem.h"
#include "util/log.h"
#include "util/stringhelper.h"

#include <fstream>

bool CodeGenerator::Generate(const string& resource) {
  void* rawData;
  size_t rawDataSize = FileSystem::GetFileData(resource, &rawData);
  if(rawDataSize == 0) {
    Debug("Failed to load resource data");
    return false;
  }
  // Stuff the resource data into a string and free memory allocated by FileSystem
  string resourceData((char*)rawData, rawDataSize);
  free(rawData);

  // Do some string formatting
  string noExtension = FileSystem::TrimExtension(resource);
  string resourceName = FileSystem::TrimPath(noExtension);

  // Extract resource objects
  vector<RCObject> objects;
  RCParser::ExtractObjects(resourceData, objects);

  // Prepare to stream data
  ostringstream headerData, sourceData;

  // Start source data
  sourceData << "/* THIS IS A GENERATED FILE */\n\n" <<
                "#include \"" << noExtension << ".h\"\n\n";

  // Start header data
  string headerDef = ToUpcase(resourceName);
  headerData << "/* THIS IS A GENERATED FILE */\n\n" <<
                "#ifndef " << headerDef << "_H\n" <<
                "#define " << headerDef << "_H\n\n" <<
                "#include \"io/eventmeta.h\"\n\n" <<
                "enum GameEventType : GameEventTypeSize {\n";

  sourceData << "GameEvent* GameEvent::Unpack(istringstream& str) {\n" <<
                "  GameEvent* ret;\n" <<
                "  GameEventType temp;\n" <<
                "  str >> temp;\n" <<
                "  switch(temp) {\n";
  for(auto object : objects) {
    string constructorArgs = "";
    bool first = true;
    for(auto field : object.fields) {
      if(!first) {
        constructorArgs += ", ";
      } else {
        first = false;
      }
      constructorArgs += field.type + " _" + field.name;
    }
    headerData << "  " << object.header << ",\n";
    sourceData << "    case " << object.header << ": ret = new " << object.header << "Event(); break;\n";
  }
  sourceData << "    default:\n" <<
                "      Error(\"Invalid event type\" << temp);\n" <<
                "      return 0;\n" <<
                "  }\n" <<
                "  ret->unpack(str);\n" <<
                "  return ret;\n" <<
                "}\n\n";

  headerData << "};\n\n";

  // Append struct and source data
  for(auto object : objects) {
    GenerateStruct(object, headerData);
    GenerateSource(object, sourceData);
  }
  headerData << "#endif" << endl;

  // Create the header file
  string headerStringData = headerData.str();
  if(!FileSystem::SaveFileData(noExtension + ".h", headerStringData.c_str(), headerStringData.size())) {
    Debug("Failed to save header data");
    return false;
  }

  // Create the source file
  string sourceStringData = sourceData.str();
  if(!FileSystem::SaveFileData(noExtension + ".cpp", sourceStringData.c_str(), sourceStringData.size())) {
    Debug("Failed to save source data");
    return false;
  }

  return true;
}

void CodeGenerator::GenerateStruct(const RCObject& object, ostringstream& structData) {
  structData << "struct " << object.header << "Event : public GameEvent {\n";

  if(object.fields.size() > 0) {
    for(auto field : object.fields) {
      structData << "  " << field.type << " " << field.name << ";\n";
    }
    structData << "\n" <<
                  "  " << ClassName(object) << "(" << ConstructorArgs(object) << ");\n";
  }

  structData << "  " << ClassName(object) << "();\n" << 
                "  void pack(ostringstream& str);\n" <<
                "  void unpack(istringstream& str);\n" <<
                "};\n\n";
}

void CodeGenerator::GenerateSource(const RCObject& object, ostringstream& sourceData) {
  string serialization = "",
         deserialization = "";

  if(object.fields.size() > 0) {
    serialization += "  str";
    deserialization += "  str";
    for(auto field : object.fields) {
      serialization += " << " + field.name;
      deserialization += " >> " + field.name;
    }
    serialization += ";\n";
    deserialization += ";\n";
    sourceData << ArgumentConstructor(object);
  }

  sourceData << DefaultConstructor(object) <<
                "void " << object.header << "Event::pack(ostringstream& str) {\n" <<
                serialization <<
                "}\n" <<
                "void " << object.header << "Event::unpack(istringstream& str) {\n" <<
                deserialization <<
                "}\n\n";
}

string CodeGenerator::DefaultConstructor(const RCObject& object) {
  return ClassName(object) + "::" + ClassName(object) + "(): GameEvent(" + object.header + ") {}\n";
}

string CodeGenerator::ArgumentConstructor(const RCObject& object) {
  return ClassName(object) + "::" + ClassName(object) + "(" + ConstructorArgs(object) + "):\n" +
         "  GameEvent(" + object.header + ") " + ConstructorInitializer(object) + " {}\n";
}

string CodeGenerator::ConstructorArgs(const RCObject& object) {
  string ret = "";

  bool first = true;
  for(auto field : object.fields) {
    if(!first) {
      ret += ", ";
    } else { first = false; }
    ret += "const " + field.type + "& _" + field.name;
  }

  return ret;
}

string CodeGenerator::ConstructorInitializer(const RCObject& object) {
  string ret = "";
  for(auto field : object.fields) {
    ret += ", " + field.name + "(_" + field.name + ")";
  }
  return ret;
}

string CodeGenerator::ClassName(const RCObject& object) {
  return object.header + "Event";
}
