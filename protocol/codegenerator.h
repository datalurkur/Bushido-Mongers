#ifndef CODE_GENERATOR_h
#define CODE_GENERATOR_h

#include "protocol/rcparser.h"

#include <string>
#include <sstream>
using namespace std;

class CodeGenerator {
public:
  static bool Generate(const string& resource);

private:
  static void GenerateStruct(const RCObject& object, ostringstream& structData);
  static void GenerateSource(const RCObject& object, ostringstream& sourceData);

  static string DefaultConstructor(const RCObject& object);
  static string ArgumentConstructor(const RCObject& object);
  static string ConstructorArgs(const RCObject& object);
  static string ConstructorInitializer(const RCObject& object);
  static string CloneArgs(const RCObject& object);
  static string ClassName(const RCObject& object);

private:
  CodeGenerator();
};

#endif
