-- IBM437 (defined in Ruby, defined by IANA)
.encoding~register("IBM437", .IBM437_Encoding)
.encoding~register("CP437", .IBM437_Encoding)               -- alias defined in Ruby, alias defined by IANA, alias defined by ICU (cp437)
.encoding~register("437", .IBM437_Encoding)                 -- alias defined by IANA, alias defined by ICU  (437)
.encoding~register("CSPC8CODEPAGE437", .IBM437_Encoding)    -- alias defined by IANA, alias defined by ICU (csPC8CodePage437)
.encoding~register("WINDOWS437", .IBM437_Encoding)          -- alias defined by ICU (windows-437)

::requires "encoding/byte_encoding.cls"
::requires "encoding/encoding.cls"

/******************************************************************************/
::class "IBM437_Encoding" subclass Byte_Encoding public

::constant name "IBM437"


::attribute tableTranscodingToUnicode class get


::method activate class
    -- https://en.wikipedia.org/wiki/Code_page_437
    -- NOT CLEAR AT ALL TO ME:
    --     When translating to Unicode some codes do not have a unique, single
    --     Unicode equivalent; the correct choice may depend upon context.
    -- 17 rules are given, I understand nothing.
    -- DECISION: I dont't use this Wikipedia table, I use this file from ICU:
    -- https://github.com/unicode-org/icu/tree/main/icu4c/source/data/mappings/ibm-437_P100-1995.ucm
    expose tableTranscodingToUnicode
    use strict arg -- none
    specificTranscoding =,
        , --    00      01      02      03      04      05      06      07      08      09      0A      0B      0C      0D      0E      0F
        "1A:",                                                                                  "001C", "=",    "007F",,
        "7F:",                                                                                                                          "001A",,
        "80:",  "00C7", "00FC", "00E9", "00E2", "00E4", "00E0", "00E5", "00E7", "00EA", "00EB", "00E8", "00EF", "00EE", "00EC", "00C4", "00C5",,
        "90:",  "00C9", "00E6", "00C6", "00F4", "00F6", "00F2", "00FB", "00F9", "00FF", "00D6", "00DC", "00A2", "00A3", "00A5", "20A7", "0192",,
        "A0:",  "00E1", "00ED", "00F3", "00FA", "00F1", "00D1", "00AA", "00BA", "00BF", "2310", "00AC", "00BD", "00BC", "00A1", "00AB", "00BB",,
        "B0:",  "2591", "2592", "2593", "2502", "2524", "2561", "2562", "2556", "2555", "2563", "2551", "2557", "255D", "255C", "255B", "2510",,
        "C0:",  "2514", "2534", "252C", "251C", "2500", "253C", "255E", "255F", "255A", "2554", "2569", "2566", "2560", "2550", "256C", "2567",,
        "D0:",  "2568", "2564", "2565", "2559", "2558", "2552", "2553", "256B", "256A", "2518", "250C", "2588", "2584", "258C", "2590", "2580",,
        "E0:",  "03B1", "00DF", "0393", "03C0", "03A3", "03C3", "03BC", "03C4", "03A6", "0398", "03A9", "03B4", "221E", "03C6", "03B5", "2229",,
        "F0:",  "2261", "00B1", "2265", "2264", "2320", "2321", "00F7", "2248", "00B0", "2219", "00B7", "221A", "207F", "00B2", "25A0", "00A0"
    tableTranscodingToUnicode = createCharacterTranscodingTable(256, specificTranscoding)

/*
    ibm-437_P100-1995.ucm sorted by 2nd column.
    all ICU aliases:
        ibm-437_P100-1995
        ibm-437
        IBM437
        cp437
        437
        csPC8CodePage437
        windows-437

    The lines where the mapping is identicial are shifted on the right.
    The lines starting at margin 1 are lines where the mapping is different from the character.

    Some characters have TWO mappings...
    I don't understand the meaning of |0 |1 and |2.
    In the ICU demo, only the mappings |0 are used. I do the same.
    https://icu4c-demos.unicode.org/icu-bin/convexp?conv=ibm-437_P100-1995

    <U0000> \x00 |0
    <U0001> \x01 |0
    <U0002> \x02 |0
    <U0003> \x03 |0
    <U0004> \x04 |0
    <U0005> \x05 |0
    <U0006> \x06 |0
    <U0007> \x07 |0
    <U0008> \x08 |0
    <U0009> \x09 |0
    <U000A> \x0A |0
    <U000B> \x0B |0
    <U000C> \x0C |0
    <U000D> \x0D |0
    <U000E> \x0E |0
    <U000F> \x0F |0
    <U0010> \x10 |0
    <U0011> \x11 |0
    <U0012> \x12 |0
    <U0013> \x13 |0
    <U0014> \x14 |0
    <U0015> \x15 |0
    <U0016> \x16 |0
    <U0017> \x17 |0
    <U0018> \x18 |0
    <U0019> \x19 |0
<U001C> \x1A |0
    <U001B> \x1B |0
<U007F> \x1C |0
    <U001D> \x1D |0
    <U001E> \x1E |0
    <U001F> \x1F |0
    <U0020> \x20 |0
    <U0021> \x21 |0
    <U0022> \x22 |0
    <U0023> \x23 |0
    <U0024> \x24 |0
    <U0025> \x25 |0
    <U0026> \x26 |0
    <U0027> \x27 |0
    <U0028> \x28 |0
    <U0029> \x29 |0
    <U002A> \x2A |0
    <U002B> \x2B |0
    <U002C> \x2C |0
    <U002D> \x2D |0
    <U002E> \x2E |0
    <U002F> \x2F |0
    <U0030> \x30 |0
    <U0031> \x31 |0
    <U0032> \x32 |0
    <U0033> \x33 |0
    <U0034> \x34 |0
    <U0035> \x35 |0
    <U0036> \x36 |0
    <U0037> \x37 |0
    <U0038> \x38 |0
    <U0039> \x39 |0
    <U003A> \x3A |0
    <U003B> \x3B |0
    <U003C> \x3C |0
    <U003D> \x3D |0
    <U003E> \x3E |0
    <U003F> \x3F |0
    <U0040> \x40 |0
    <U0041> \x41 |0
    <U0042> \x42 |0
    <U0043> \x43 |0
    <U0044> \x44 |0
    <U0045> \x45 |0
    <U0046> \x46 |0
    <U0047> \x47 |0
    <U0048> \x48 |0
    <U0049> \x49 |0
    <U004A> \x4A |0
    <U004B> \x4B |0
    <U004C> \x4C |0
    <U004D> \x4D |0
    <U004E> \x4E |0
    <U004F> \x4F |0
    <U0050> \x50 |0
    <U0051> \x51 |0
    <U0052> \x52 |0
    <U0053> \x53 |0
    <U0054> \x54 |0
    <U0055> \x55 |0
    <U0056> \x56 |0
    <U0057> \x57 |0
    <U0058> \x58 |0
    <U0059> \x59 |0
    <U005A> \x5A |0
    <U005B> \x5B |0
    <U005C> \x5C |0
    <U005D> \x5D |0
    <U005E> \x5E |0
    <U005F> \x5F |0
    <U0060> \x60 |0
    <U0061> \x61 |0
    <U0062> \x62 |0
    <U0063> \x63 |0
    <U0064> \x64 |0
    <U0065> \x65 |0
    <U0066> \x66 |0
    <U0067> \x67 |0
    <U0068> \x68 |0
    <U0069> \x69 |0
    <U006A> \x6A |0
    <U006B> \x6B |0
    <U006C> \x6C |0
    <U006D> \x6D |0
    <U006E> \x6E |0
    <U006F> \x6F |0
    <U0070> \x70 |0
    <U0071> \x71 |0
    <U0072> \x72 |0
    <U0073> \x73 |0
    <U0074> \x74 |0
    <U0075> \x75 |0
    <U0076> \x76 |0
    <U0077> \x77 |0
    <U0078> \x78 |0
    <U0079> \x79 |0
    <U007A> \x7A |0
    <U007B> \x7B |0
    <U007C> \x7C |0
    <U007D> \x7D |0
    <U007E> \x7E |0
<U001A> \x7F |0
<U00C7> \x80 |0
<U00FC> \x81 |0
<U00E9> \x82 |0
<U00E2> \x83 |0
<U00E4> \x84 |0
<U00E0> \x85 |0
<U00E5> \x86 |0
<U00E7> \x87 |0
<U00EA> \x88 |0
<U00EB> \x89 |0
<U00E8> \x8A |0
<U00EF> \x8B |0
<U00EE> \x8C |0
<U00EC> \x8D |0
<U00C4> \x8E |0
<U00C5> \x8F |0
<U00C9> \x90 |0
<U00E6> \x91 |0
<U00C6> \x92 |0
<U00F4> \x93 |0
<U00F6> \x94 |0
<U00F2> \x95 |0
<U00FB> \x96 |0
<U00F9> \x97 |0
<U00FF> \x98 |0
<U00D6> \x99 |0
<U00DC> \x9A |0
<U00A2> \x9B |0
<U00A3> \x9C |0
<U00A5> \x9D |0
<U20A7> \x9E |0
<U0192> \x9F |0
<U00E1> \xA0 |0
<U00ED> \xA1 |0
<U00F3> \xA2 |0
<U00FA> \xA3 |0
<U00F1> \xA4 |0
<U00D1> \xA5 |0
<U00AA> \xA6 |0
<U00BA> \xA7 |0
<U00BF> \xA8 |0
<U2310> \xA9 |0
<U00AC> \xAA |0
<U00BD> \xAB |0
<U00BC> \xAC |0
<U00A1> \xAD |0
<U00AB> \xAE |0
<U00BB> \xAF |0
<U2591> \xB0 |0
<U2592> \xB1 |0
<U2593> \xB2 |0
<U2502> \xB3 |0
<U2524> \xB4 |0
<U2561> \xB5 |0
<U2562> \xB6 |0
<U2556> \xB7 |0
<U2555> \xB8 |0
<U2563> \xB9 |0
<U2551> \xBA |0
<U2557> \xBB |0
<U255D> \xBC |0
<U255C> \xBD |0
<U255B> \xBE |0
<U2510> \xBF |0
<U2514> \xC0 |0
<U2534> \xC1 |0
<U252C> \xC2 |0
<U251C> \xC3 |0
<U2500> \xC4 |0
<U253C> \xC5 |0
<U255E> \xC6 |0
<U255F> \xC7 |0
<U255A> \xC8 |0
<U2554> \xC9 |0
<U2569> \xCA |0
<U2566> \xCB |0
<U2560> \xCC |0
<U2550> \xCD |0
<U256C> \xCE |0
<U2567> \xCF |0
<U2568> \xD0 |0
<U2564> \xD1 |0
<U2565> \xD2 |0
<U2559> \xD3 |0
<U2558> \xD4 |0
<U2552> \xD5 |0
<U2553> \xD6 |0
<U256B> \xD7 |0
<U256A> \xD8 |0
<U2518> \xD9 |0
<U250C> \xDA |0
<U2588> \xDB |0
<U2584> \xDC |0
<U258C> \xDD |0
<U2590> \xDE |0
<U2580> \xDF |0
<U03B1> \xE0 |0
<U00DF> \xE1 |0
<U0393> \xE2 |0
<U03C0> \xE3 |0
<U03A3> \xE4 |0
<U03C3> \xE5 |0
<U03BC> \xE6 |0
<U03C4> \xE7 |0
<U03A6> \xE8 |0
<U0398> \xE9 |0
<U03A9> \xEA |0
<U03B4> \xEB |0
<U221E> \xEC |0
<U03C6> \xED |0
<U03B5> \xEE |0
<U2229> \xEF |0
<U2261> \xF0 |0
<U00B1> \xF1 |0
<U2265> \xF2 |0
<U2264> \xF3 |0
<U2320> \xF4 |0
<U2321> \xF5 |0
<U00F7> \xF6 |0
<U2248> \xF7 |0
<U00B0> \xF8 |0
<U2219> \xF9 |0
<U00B7> \xFA |0
<U221A> \xFB |0
<U207F> \xFC |0
<U00B2> \xFD |0
<U25A0> \xFE |0
<U00A0> \xFF |0


<U263A> \x01 |1
<U263B> \x02 |1
<U2665> \x03 |1
<U2666> \x04 |1
<U2663> \x05 |1
<U2660> \x06 |1
<U2022> \x07 |1
<U25D8> \x08 |1
<U25CB> \x09 |1         ???
<UFFEE> \x09 |1         ???
<U25D9> \x0A |1
<U2642> \x0B |1
<U2640> \x0C |1
<U266A> \x0D |1
<U266B> \x0E |1
<U263C> \x0F |1
<U25BA> \x10 |1
<U25C4> \x11 |1
<U2195> \x12 |1
<U203C> \x13 |1
<U00B6> \x14 |1
<U00A7> \x15 |1
<U25AC> \x16 |1
<U21A8> \x17 |1
<U2191> \x18 |1         ???
<UFFEA> \x18 |1         ???
<U2193> \x19 |1         ???
<UFFEC> \x19 |1         ???
<U2192> \x1A |1         ???
<UFFEB> \x1A |1         ???
<U2190> \x1B |1         ???
<UFFE9> \x1B |1         ???
<U221F> \x1C |1
<U2194> \x1D |1
<U25B2> \x1E |1
<U25BC> \x1F |1
<UFF01> \x21 |1
<UFF02> \x22 |1
<UFF03> \x23 |1
<UFF04> \x24 |1
<UFF05> \x25 |1
<UFF06> \x26 |1
<UFF07> \x27 |1
<UFF08> \x28 |1
<UFF09> \x29 |1
<UFF0A> \x2A |1
<UFF0B> \x2B |1
<UFF0C> \x2C |1
<UFF0D> \x2D |1
<UFF0E> \x2E |1
<UFF0F> \x2F |1
<UFF10> \x30 |1
<UFF11> \x31 |1
<UFF12> \x32 |1
<UFF13> \x33 |1
<UFF14> \x34 |1
<UFF15> \x35 |1
<UFF16> \x36 |1
<UFF17> \x37 |1
<UFF18> \x38 |1
<UFF19> \x39 |1
<UFF1A> \x3A |1
<UFF1B> \x3B |1
<UFF1C> \x3C |1
<UFF1D> \x3D |1
<UFF1E> \x3E |1
<UFF1F> \x3F |1
<UFF20> \x40 |1
<UFF21> \x41 |1
<UFF22> \x42 |1
<UFF23> \x43 |1
<UFF24> \x44 |1
<UFF25> \x45 |1
<UFF26> \x46 |1
<UFF27> \x47 |1
<UFF28> \x48 |1
<UFF29> \x49 |1
<UFF2A> \x4A |1
<UFF2B> \x4B |1
<UFF2C> \x4C |1
<UFF2D> \x4D |1
<UFF2E> \x4E |1
<UFF2F> \x4F |1
<UFF30> \x50 |1
<UFF31> \x51 |1
<UFF32> \x52 |1
<UFF33> \x53 |1
<UFF34> \x54 |1
<UFF35> \x55 |1
<UFF36> \x56 |1
<UFF37> \x57 |1
<UFF38> \x58 |1
<UFF39> \x59 |1
<UFF3A> \x5A |1
<UFF3B> \x5B |1
<UFF3C> \x5C |1
<UFF3D> \x5D |1
<UFF3E> \x5E |1
<UFF3F> \x5F |1
<UFF40> \x60 |1
<UFF41> \x61 |1
<UFF42> \x62 |1
<UFF43> \x63 |1
<UFF44> \x64 |1
<UFF45> \x65 |1
<UFF46> \x66 |1
<UFF47> \x67 |1
<UFF48> \x68 |1
<UFF49> \x69 |1
<UFF4A> \x6A |1
<UFF4B> \x6B |1
<UFF4C> \x6C |1
<UFF4D> \x6D |1
<UFF4E> \x6E |1
<UFF4F> \x6F |1
<UFF50> \x70 |1
<UFF51> \x71 |1
<UFF52> \x72 |1
<UFF53> \x73 |1
<UFF54> \x74 |1
<UFF55> \x75 |1
<UFF56> \x76 |1
<UFF57> \x77 |1
<UFF58> \x78 |1
<UFF59> \x79 |1
<UFF5A> \x7A |1
<UFF5B> \x7B |1
<UFF5C> \x7C |1
<UFF5D> \x7D |1
<UFF5E> \x7E |1
<UFFE8> \xB3 |1
<UFFED> \xFE |1


<U2302> \x7F |2

*/
