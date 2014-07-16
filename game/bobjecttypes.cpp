#include "game/bobjecttypes.h"

void bufferToStream(ostringstream& str, const BObjectType& val) { genericBufferToStream(str, val); }
void bufferFromStream(istringstream& str, BObjectType& val) { genericBufferFromStream(str, val); }
void bufferToStream(ostringstream& str, const ObjectSectionType& val) { genericBufferToStream(str, val); }
void bufferFromStream(istringstream& str, ObjectSectionType& val) { genericBufferFromStream(str, val); }
void bufferToStream(ostringstream& str, const AttributeSectionType& val) { genericBufferToStream(str, val); }
void bufferFromStream(istringstream& str, AttributeSectionType& val) { genericBufferFromStream(str, val); }
void bufferToStream(ostringstream& str, const ExtensionType& val) { genericBufferToStream(str, val); }
void bufferFromStream(istringstream& str, ExtensionType& val) { genericBufferFromStream(str, val); }
