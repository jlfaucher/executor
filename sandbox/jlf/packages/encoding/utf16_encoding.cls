.encoding~register("UTF16", .UTF16BE_Encoding)
.encoding~register("UTF16BE", .UTF16BE_Encoding)
.encoding~register("UTF16LE", .UTF16LE_Encoding)
--.encoding~register("UCS2BE", .UTF16BE_Encoding)     -- Alias defined in Ruby, but I'm not convinced it's a good alias for UTF-16

::requires "encoding/encoding.cls"
::requires "encoding/utf16_common.cls"
::requires "encoding/unicode_common.cls"
::requires "encoding/stringIndexer.cls"


/******************************************************************************/
::class "UTF16BE_Encoding" public inherit UTF16_CommonServices XTF16BE_CommonServices XTF16_CommonServices Unicode_CommonServices StringIndexer

::constant name "UTF-16BE"
::constant isUTF16 1
::constant isUTF16BE 1
::constant BOM "FE FF"x


/******************************************************************************/
::class "UTF16LE_Encoding" public inherit UTF16_CommonServices XTF16LE_CommonServices XTF16_CommonServices Unicode_CommonServices StringIndexer

::constant name "UTF-16LE"
::constant isUTF16 1
::constant isUTF16LE 1
::constant BOM "FF FE"x
