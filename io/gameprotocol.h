#ifndef GAME_PROTOCOL_H
#define GAME_PROTOCOL_H

#include "util/packing.h"

#define PROTOCOL_MAJOR_VERSION 0
#define PROTOCOL_MINOR_VERSION 1

enum PayloadType {
  LoginRequest,
  LoginResponse
};

struct Payload {
  PayloadType type;

  Payload(PayloadType t): type(t) {}

  static Payload* Unpack(void* data, unsigned int size) {
    unsigned int offset;
    PayloadType t;
    ReadFromBuffer<PayloadType>(data, size, offset, t);

    void* offsetBuffer = (void*)((char*)offsetBuffer + offset);
    unsigned int offsetSize = size - offset;

    switch(t) {
    case LoginRequest:
      return LoginRequest.Unpack(offsetBuffer, offsetSize);
    case LoginResponse:
      return LoginResponse.Unpack(offsetBuffer, offsetSize);
    default:
      Error("Unpacking not implemented for payload type " << t);
      return 0;
    }
  }
};

struct LoginRequest: public Payload {
  string name;
  char majorVersion;
  char minorVersion;

  LoginRequest();
  LoginRequest(const string& n, char maj = PROTOCOL_MAJOR_VERSION, char min = PROTOCOL_MINOR_VERSION):
    Payload(PayloadType::LoginRequest), name(n), majorVersion(maj), minorVersion(min) {}

  static Payload* Unpack(void* data, unsigned int size) {
    unsigned int offset;

    unsigned short nameSize;
    ReadFromBuffer<unsigned short>(data, size, offset, nameSize);
    char* nameData = calloc(nameSize+1, sizeof(char));
    ReadFromBuffer(data, size, offset, nameData, nameSize);

    ReadFromBuffer<char>(data, size, offset, majorVersion);

    ReadFromBuffer<char>(data, size, offset, minorVersion);

    Payload* p = new LoginRequest(string(nameData), maj, min);
    free(nameData);

    return p;
  }
};

struct LoginResponse: public Payload {
  bool granted;
  
  LoginResponse();
  LoginResponse(bool g): Payload(PayloadType::LoginResponse), granted(g) {}

  static Payload* Unpack(void* data, unsigned int size) {
    unsigned int offset;
    bool g;
    ReadFromBuffer<bool>(data, size, offset, g);
    return new LoginResponse(g);
  }
};

#endif
