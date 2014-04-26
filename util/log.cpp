#include "log.h"
#include "platform.h"

Log* Log::OutputStream = 0;
LogChannel Log::ChannelState = 0;
bool Log::StdoutEnabled = true;
set<LogListener*> Log::Listeners;
mutex Log::Mutex;

Log::Log(const string& logfile): _cleanupStream(true) {
  _logFile = new filebuf;
  _logFile->open(logfile.c_str(), ios::out);
  _outputStream = new std::ostream(_logFile);
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

void Log::Setup(const string& logfile) {
  if(!OutputStream) {
    OutputStream = new Log(logfile);
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

void Log::RegisterListener(LogListener* listener) {
  Listeners.insert(listener);
}

void Log::UnregisterListener(LogListener* listener) {
  Listeners.erase(listener);
}

void Log::SendToListeners(LogChannel channel, const string& message) {
  for(auto listener : Listeners) {
    listener->logMessage(channel, message);
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

Log& Log::GetLogStream() {
  return *OutputStream;
}

void Log::EnableStdout() {
  StdoutEnabled = true;
}

void Log::DisableStdout() {
  StdoutEnabled = false;
}

void Log::Flush() {
  OutputStream->flush();
}

void Log::flush() {
  _outputStream->flush();
  if(StdoutEnabled) {
    std::cout.flush();
  }
}
