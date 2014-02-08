#include "log.h"
#include "platform.h"

Log* Log::OutputStream = 0;
LogChannel Log::ChannelState = 0;

Log::Log(): _cleanupStream(false), _outputStream(&std::cout), _logFile(0) {
#if SYS_PLATFORM == PLATFORM_WIN32
  _logFile = new filebuf;
  _logFile->open("stdout", ios::out);
  _outputStream = new std::ostream(_logFile);
  _cleanupStream = true;
#endif
}

Log::~Log() {
  _outputStream->flush();

  if(_logFile) {
    _logFile->close();
    delete _logFile;
    _logFile = 0;
  }

  if(_cleanupStream) {
    delete _outputStream;
    _cleanupStream = false;
  }
}

void Log::Setup() {
  if(!OutputStream) {
    OutputStream = new Log();
  }
  EnableAllChannels();
}

void Log::Teardown() {
  DisableAllChannels();
  if(OutputStream) {
    delete OutputStream;
    OutputStream = 0;
  }
}

void Log::EnableAllChannels() {
  ChannelState = ~0x00;
}

void Log::DisableAllChannels() {
  ChannelState = 0x00;
}

void Log::EnableChannel(LogChannel channel) {
  ChannelState |= channel;
}

void Log::DisableChannel(LogChannel channel) {
  ChannelState &= ~channel;
}

bool Log::IsChannelEnabled(LogChannel channel) {
  return (ChannelState & channel) != 0;
}

Log& Log::GetLogStream(LogChannel channel) {
  return *OutputStream;
}

void Log::Flush() {
  OutputStream->flush();
}

void Log::flush() {
  _outputStream->flush();
}
