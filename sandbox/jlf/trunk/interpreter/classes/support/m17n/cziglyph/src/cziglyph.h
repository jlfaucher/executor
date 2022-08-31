#ifndef CZIGLYPH_H
#define CZIGLYPH_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void ziglyph_toTitleStr(const uint8_t * utf8str, uintptr_t length, const uint8_t * * out_utf8str, uintptr_t * out_length);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CZIGLYPH_H
