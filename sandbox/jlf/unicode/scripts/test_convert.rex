/*
Usage:
rexx test_convert.rex > test_convert-output.txt
*/

s = "hello"
t_BYTE    = s~text("BYTE"); call all_conversions t_BYTE

s = "ꎅꎜꏑ🦖"
t_UTF8    = s~text("UTF8"); call all_conversions t_UTF8

t_UTF16   = t_UTF8~UTF16;   call all_conversions t_UTF16
t_UTF16BE = t_UTF8~UTF16BE; call all_conversions t_UTF16BE
t_UTF16LE = t_UTF8~UTF16LE; call all_conversions t_UTF16LE

t_WTF16   = t_UTF8~WTF16;   call all_conversions t_WTF16
t_WTF16BE = t_UTF8~WTF16BE; call all_conversions t_WTF16BE
t_WTF16LE = t_UTF8~WTF16LE; call all_conversions t_WTF16LE

t_UTF32   = t_UTF8~UTF32;   call all_conversions t_UTF32
t_UTF32BE = t_UTF8~UTF32BE; call all_conversions t_UTF32BE
t_UTF32LE = t_UTF8~UTF32LE; call all_conversions t_UTF32LE


::routine all_conversions
    use strict arg t

    call infos t, "UTF8"
    call infos t, "WTF8"

    call infos t, "UTF16"
    call infos t, "UTF16BE"
    call infos t, "UTF16LE"

    call infos t, "WTF16"
    call infos t, "WTF16BE"
    call infos t, "WTF16LE"

    call infos t, "UTF32"
    call infos t, "UTF32BE"
    call infos t, "UTF32LE"

    return

    infos: procedure
        use strict arg t, m
        call charout , t~encoding~name t~c2x "--> "
        tc = t~send(m)
        call charout , tc~send("is"m) tc~encoding~name tc~c2x ";" tc~c2u
        say
        return


::requires "extension/extensions.cls"
--::options trace i
