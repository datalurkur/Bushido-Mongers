#include "protocol/codegenerator.h"
#include "util/log.h"

int main(int argc, char** argv) {
  Log::Setup();
  if(argc < 2) {
    Error("Usage: protocol_generator <resource file>");
    Log::Teardown();
    return 1;
  }

  bool ret = CodeGenerator::Generate(argv[1]);
  Log::Teardown();
  return ret ? 0 : 1;
}
