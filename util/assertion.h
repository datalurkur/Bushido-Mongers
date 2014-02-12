#ifndef ASSERTION_H
#define ASSERTION_H

#include "util/log.h"

#if SYS_PLATFORM == PLATFORM_APPLE
# define ASSERT_FUNCTION __asm__("int $03")
#elif SYS_PLATFORM == PLATFORM_WIN32
# define ASSERT_FUNCTION __asm { int 3 }
#else
# include <assert.h>
# define ASSERT(conditional, message) assert(conditional)
#endif

#ifndef ASSERT
# ifdef DEBUG
/*
#  define ASSERT(conditional) \
    do { \
      if(!(conditional)) { \
        Error("Assertion in " << __FILE__ << ":" << __LINE__ << " hit."); \
        ASSERT_FUNCTION; \
      } \
    } while(false)
*/
#  define ASSERT(conditional, message) \
    do { \
      if(!(conditional)) { \
        Error("Assertion in " << __FILE__ << ":" << __LINE__ << " hit : " << message); \
        ASSERT_FUNCTION; \
      } \
    } while(false)
# else
//#  define ASSERT(conditional) do { } while(false)
#  define ASSERT(conditional, message) do { } while(false)
# endif
#endif

#endif
