/****************************************************************************/
/* Section: Stream Accessors */
/****************************************************************************/

STREAM::StreamType STREAM::GetType()
{
    if (this == NULL) return NullStream;
    return this->type;
}


#define STREAMTYPE_TEXT(TYPE) case TYPE: return _T(#TYPE)

GtCString STREAM::StreamType2String(StreamType type)
{
    switch (type) {
        STREAMTYPE_TEXT(FileStream);
        STREAMTYPE_TEXT(MemoryStream);
        STREAMTYPE_TEXT(NullStream);
    }

    return _T("");
}


GtBool STREAM::IsPrivateClipboard()
{
    if (this == NULL) return Notify(GtFalse);
    return this->isPrivateClipboard;
}


GtBool STREAM::IsTextStream()
{
    if (this == NULL) return Notify(GtFalse);
    return (this->isTextStream == GtTrue) ? GtTrue : GtFalse;
}


GtBool STREAM::IsBinaryStream()
{
    if (this == NULL) return Notify(GtFalse);
    return (this->isTextStream == GtFalse) ? GtTrue : GtFalse;
}

GtBool STREAM::IsByteStream()
{
    if (this == NULL) return Notify(GtFalse);
    return (this->isByteStream == GtTrue) ? GtTrue : GtFalse;
}


GtBool STREAM::IsWideStream()
{
    if (this == NULL) return Notify(GtFalse);
    return (this->isByteStream == GtFalse) ? GtTrue : GtFalse;
}


int STREAM::IsError()
{
    if (this == NULL) return 1; // 1 to indicate an error
    if (this->type == FileStream) return ferror(this->filePtr);
    return (this->buf > this->bufEnd); // Yes ! The IsError function is called during write operations. So, a buffer overflow is an error.
}


int STREAM::IsEof()
{
    if (this == NULL) return 1; // 1 to indicate an error
    if (this->type == FileStream) return feof(this->filePtr);
    return (this->buf > this->bufEnd);
}


gtint32 STREAM::GetCount()
{
    if (this == NULL) return 0;
    return this->count;
}


gtuint32 STREAM::GetPos() // Like ftell
{
    if (this == NULL) return -1; // -1 to indicate an error
    if (this->type == FileStream) return ftell(this->filePtr);
    gtuint32 offset = this->buf - this->bufStart;
    return offset;
}


// Do NOT use this method on memory streams if you want an ACCURATE 'count' attribute...
GtBool STREAM::SetPos(gtuint32 pos) // Like fseek
{
    if (this == NULL) return Notify(GtFalse);
    if (this->type == FileStream) 
    {
        int status = fseek(this->filePtr, pos, 0); // fseek returns 0 if successful
        return (status == 0) ? GtTrue : Notify(GtFalse);
    }
    gtuint8 *newbuf = this->bufStart + pos;
    if (newbuf < this->bufStart) return Notify(GtFalse); // I know, can't be lesser
    if (newbuf > this->bufEnd) return Notify(GtFalse);
    this->buf = newbuf;
    return GtTrue;
}


GtBool STREAM::SetFmt(int value)
{
    if (this == NULL) return Notify(GtFalse);
    this->fmt = value;
    return GtTrue;
}


/****************************************************************************/
/* Section: Stream Factory */
/****************************************************************************/

STREAM::STREAM()
{
    if (this == NULL) return;

    memset(this, 0, sizeof(STREAM));

    this->isPrivateClipboard = GtFalse;                
    this->fmt = 0;

    this->isTextStream = GtFalse; // Null streams are always binary streams. Indeed, null streams
                                  // are used to calculate the size that would be necessary for a
                                  // memory stream. Because memory streams are always binary streams,
                                  // so are null streams...
#ifdef TOOL_UNICODE
    this->isByteStream = GtFalse; // When compiled with Unicode support, null streams are wide streams.
#else
    this->isByteStream = GtTrue; // When not compiled with Unicode support, null streams are byte streams.
#endif

    this->type = NullStream;
    this->count = 0L;
}


STREAM * TOOL_PUBLIC OpenNullStream(void)
{    
    return new STREAM;
}    
                    

void STREAM::Constructor(gtuint8 *buf, gtuint32 size) // size in bytes
{
    if (this == NULL) return;

    memset(this, 0, sizeof(STREAM));

    this->isPrivateClipboard = GtFalse;
    this->fmt = 0;

    this->isTextStream = GtFalse; // Memory streams are binary streams.
#ifdef TOOL_UNICODE
    this->isByteStream = GtFalse; // When compiled with Unicode support, memory streams are wide streams.
#else
    this->isByteStream = GtTrue; // When not compiled with Unicode support, memory streams are byte streams.
#endif

    this->type = MemoryStream;
    this->buf = buf;
    this->bufStart = this->buf; // just to be able to check that the parameter passed to SetPos is valid.
    this->bufEnd = this->buf + size - 1;
}


STREAM::STREAM(gtuint8 *buf, gtuint32 size) // size in bytes
{
    this->Constructor(buf, size);
}


STREAM * TOOL_PUBLIC OpenMemoryStream(/* char* */ gtuint8 *buf, gtuint32 size) // size in bytes
{    
    return new STREAM(buf, size);
}


STREAM::STREAM(gtuint8 *buf, gtuint32 size, GtBool privateClipboard) // size in bytes
{
    if (this == NULL) return;
    this->Constructor(buf, size);

    this->isPrivateClipboard = privateClipboard;
    if (privateClipboard) this->start = buf;
}


STREAM *TOOL_PUBLIC OpenMemoryStreamPrivateClipboard (gtuint8 *buf, gtuint32 size, GtBool privateClipboard) // size in bytes
{
    return new STREAM(buf, size, privateClipboard);
}


// If this value is found at the begining of a binary file, then the characters
// in this file are considered wide characters.
// Windows being little-endian, the sequence 0xFF 0xFE is used, as specified by
// the Unicode consortium.
static gtuint16 UnicodeBOM = 0xFEFF; // Byte Order Mark

void STREAM::Constructor(GtCString fileName, GtCString mode, GtBool &ok)
{
    ok = GtFalse;
    if (this == NULL) return;

    memset(this, 0, sizeof(STREAM));
    
    FILE *filePtr = _tfopen(fileName, mode);
    if (filePtr == (FILE *) 0) return;
    this->type    = FileStream;
    this->filePtr = filePtr;

    this->isPrivateClipboard = GtFalse;
    this->fmt = 0;

    this->isTextStream = (gtstrpbrk(mode, _T("bB")) == NULL) ? GtTrue : GtFalse;
    this->isByteStream = GtFalse;
    if (this->IsBinaryStream())
    {
        if (gtstrpbrk(mode, _T("r")))
        {
            // Opened in read mode :
            // "r" : Opens for reading. If the file does not exist or cannot be found, the fopen
            //       call fails.
            // "r+": Opens for both reading and writing. (The file must exist.) 
            gtuint16 word;
            GtBool done = this->GetWord(&word);
            if (done && word == UnicodeBOM)
            {
                this->isByteStream = GtFalse;
            }
            else 
            {
                // No BOM : Let's consider it's a byte binary stream. Useful to read legacy (byte) files
                this->UngetWord(word);
                this->isByteStream = GtTrue;
            }
        }
        else if (gtstrpbrk(mode, _T("w")))
        {
            // Opened in write mode :
            // "w" : Opens an empty file for writing. If the given file exists, its contents are
            //       destroyed.
            // "w+": Opens an empty file for both reading and writing. If the given file exists,
            //       its contents are destroyed.
#ifdef TOOL_UNICODE
            this->isByteStream = GtFalse;
            GtBool done = this->PutWord(UnicodeBOM);
            if (!done)
            {
                // Unable to write the BOM. Sounds bad !
                ok = GtFalse;
                return;
            }
#else
            this->isByteStream = GtTrue;
#endif
        }
        else
        {
            // More difficult... Can be opened with a or a+ :
            // "a" : Opens for writing at the end of the file (appending) without removing the EOF
            //       marker before writing new data to the file; creates the file first if it
            //       doesn't exist
            // "a+": Opens for reading and appending; the appending operation includes the removal
            //       of the EOF marker before new data is written to the file and the EOF marker is
            //       restored after writing is complete; creates the file first if it doesn't exist.
            // Because I have no way to read or write easily at the begining of the file, I consider
            // that the file contains byte characters (this is consistent with the lack of BOM).
            // Anyway, TOOL itself does not use "a" or "a+", so it's not very important...
            this->isByteStream = GtTrue;
        }
    }
    else
    {
        // Text stream
#ifdef TOOL_UNICODE
        this->isByteStream = GtFalse; // When compiled with Unicode support, a text stream is
                                      // considered multi-byte (i.e. a sequence of one to four
                                      // bytes per character).
                                      // This does not forbid to read/write "pure" ascii files !
                                      // For example, the gtd files can be read without problem.
#else
        this->isByteStream = GtTrue; // When not compiled with Unicode support, a text stream is
                                     // always a byte stream.
#endif
    }

    ok = GtTrue;
}


STREAM::STREAM(GtCString fileName, GtCString mode, GtBool &ok)
{
    this->Constructor(fileName, mode, ok);
}


STREAM * TOOL_PUBLIC OpenFileStream(GtCString fileName, GtCString mode)
{
    GtBool ok;
    STREAM *stream = new STREAM(fileName, mode, ok);
    if (stream == NULL) return NULL;
    if (ok == GtFalse) 
    {
        delete stream;
        Notify(GtFalse); // To activate breakpoint, if any
        return NULL;
    }

    return stream;
}


STREAM::STREAM(GtCString fileName, GtCString mode, GtBool privateClipboard, GtBool &ok)
{
    if (this == NULL) return;
    this->Constructor(fileName, mode, ok);
    if (ok == GtFalse) return;

    this->isPrivateClipboard = privateClipboard;
    if (privateClipboard) this->buf = buf;

    ok = GtTrue;
}


STREAM * TOOL_PUBLIC OpenFileStreamPrivateClipboard (GtCString fileName, GtCString mode, GtBool privateClipboard)
{
    GtBool ok;
    STREAM *stream = new STREAM(fileName, mode, privateClipboard, ok);
    if (stream == NULL) return NULL;
    if (ok == GtFalse) 
    {
        delete stream;
        Notify(GtFalse); // To activate breakpoint, if any
        return NULL;
    }
    return stream;
}

STREAM::~STREAM()
{
}


GtBool STREAM::CloseStream()
{
    if (this == NULL) return Notify(GtFalse);

    GtBool closeOk = GtFalse;

    switch (this->type)  {
    case FileStream: 
        closeOk = (GtBool) (fclose(this->filePtr) == 0);
        this->filePtr = NULL;
        break;
    }

    return closeOk;
}


GtBool TOOL_PUBLIC CloseStream(STREAM *stream)
{        
    GtBool closeOk = stream->CloseStream();

    // Free the memory only for classic streams
    if (!stream->IsPrivateClipboard()) delete stream;

    return closeOk;
}         


/****************************************************************************/
/* Section: Reading/Writing Bytes */
/****************************************************************************/

GtBool STREAM::GetByte(gtuint8 *pByte)
{
    if (pByte == NULL)
    {
        return Notify(GtFalse);
    }

    *pByte = 0;
    if (this == NULL) 
    {
        return Notify(GtFalse);
    }

    switch (this->type)
    { 
    case MemoryStream:
        if (this->buf > this->bufEnd)
        {
            return Notify(GtFalse);
        }
        *pByte  = *this->buf++; 
        break;
    case FileStream:
        *pByte = getc(this->filePtr); // Yes ! Byte version
        if (this->IsError() || this->IsEof()) 
        {
            return Notify(GtFalse); 
        }

        break; 
    case NullStream:
        *pByte = 0; 
        break;
    }
  return GtTrue;   
}


// Why gtuint16 byte ? It's a 8 bits value which is returned !
GtBool TOOL_PUBLIC GetByte(gtuint16 *pByte, STREAM *stream)
{  
    *pByte = 0;
    gtuint8 byte;
    GtBool done = stream->GetByte(&byte);
    *pByte = byte;
    return done;
}   
    

void STREAM::UngetByte(gtuint8 byte)
{
    if (this == NULL)
    {
        return;
    }

    switch (this->type)
    { 
    case MemoryStream:
        --this->buf;

        // To me, it sounds dangerous to store such a value in a MemoryStream.
        // Indeed, most of the time, the buffer of a MemoryStream is directly a pointer
        // to the value associated to an OBJString.
        // Normally, an unget does not modify the buffer, since you are expected to store
        // the previous value. But what happens if you do a mistake ?
        _ASSERTE(*this->buf == byte); // At least, that way, I know if someone does a mistake.
        *this->buf = byte;  
        break;
    case FileStream: 
        {
        int c = ungetc(byte, this->filePtr); // Yes ! Byte version
        _ASSERTE(c == byte); // I'm fighting against a mysterious EOF error. Is there soething wrong here ?
        }
        break;
    case NullStream:
        this->count -= sizeof(gtuint8);
        break;
    }                 
}


void TOOL_PUBLIC UngetByte(gtuint16 byte, STREAM *stream)
{
    stream->UngetByte((gtuint8)byte);
} 


GtBool STREAM::PutByte(gtuint8 byte)
{
    if (this == NULL)
    {
        return Notify(GtFalse);
    }

    switch (this->type) {
    case MemoryStream:
        if (this->buf == this->bufEnd)
        {
            return Notify(GtFalse);
        }
        *this->buf++ = byte; 
        break;
    case FileStream:
        putc(byte, this->filePtr); // Yes ! Byte version
        if (this->IsError())
        {
            return Notify(GtFalse);
        }
        break;
    case NullStream:
        this->count += sizeof(gtuint8);
        break;
    }
    return GtTrue; 
}


GtBool TOOL_PUBLIC PutByte(gtuint16 byte, STREAM *stream)
{
    return stream->PutByte((gtuint8)byte);
}


/****************************************************************************/
/* Section: Reading/Writing Characters */
/****************************************************************************/

GtBool STREAM::GetChar(gtchar *pCharacter)
{
    if (pCharacter == NULL)
    {
        return Notify(GtFalse);
    }

    *pCharacter = 0;
    if (this == NULL)
    {
        return Notify(GtFalse);
    }

    switch (this->type)
    { 
    case MemoryStream:
        {
#ifdef TOOL_UNICODE
            // A memory stream is always in binary mode, so no need to test if text mode
            GtBool done = this->GetWord(pCharacter);
#else
            gtuint8 byte;
            GtBool done = this->GetByte(&byte);
            *pCharacter = byte;
#endif
            if (!done)
            {
                return Notify(GtFalse);
            }
            break;
        }
    case FileStream:
        {
#if 0 // Don't know why, but sometimes _gettc returns an erroneous value when reading
      // a binary file in Unicode mode. By "sometimes", I mean "one error for hundred
      // thousands of read operations".
      // I spent three weeks of debugging, hacking, dumping to reach this conclusion :
      // Don't use anymore the _gettc function to read binary wide streams.
        *pCharacter = _gettc(this->filePtr); // Yes ! Generic version
#else
#ifdef TOOL_UNICODE
        if (this->IsBinaryStream())
        {
            if (this->IsWideStream())
            {
                this->GetWord(pCharacter);
            }
            else
            {
                gtuint8 character;
                this->GetByte(&character);
                character = TO_ISO_CHAR(character); // Keep it to read legacy byte files.
                *pCharacter = character;
            }
        }
        else
        {
            // From MSDN :
            // A wide stream treats a text stream as a sequence of generalized multibyte characters,
            // which can have a broad range of encoding rules.
            // Two kinds of character conversions take place:
            // - MBCS-to-Unicode
            // - CR-LF translation
            *pCharacter = _gettc(this->filePtr);
        }
#else
        gtuint8 character;
        GtBool done = this->GetByte(&character);
        if (this->IsBinaryStream()) character = TO_ISO_CHAR(character); // Keep it to read legacy byte files.
        *pCharacter = character;
#endif
#endif
        if (this->IsError() || this->IsEof())
        {
            return Notify(GtFalse); 
        }

        break; 
        }
    case NullStream:
        *pCharacter = 0; 
        break;
    }
  return GtTrue;   
}


GtBool TOOL_PUBLIC GetChar(gtchar *pCharacter, STREAM *stream)
{
    return stream->GetChar(pCharacter);
}


GtBool STREAM::PutChar(gtchar character)
{
    if (this == NULL)
    {
        return Notify(GtFalse);
    }

    switch (this->type) {
    case MemoryStream:
        {
#ifdef TOOL_UNICODE
            // A memory stream is always in binary mode, so no need to test if text mode
            GtBool done = this->PutWord(character);
#else
            GtBool done = this->PutByte(character);
#endif
            return done;
            break;
        }
    case FileStream:
        {
#if 0
        // I no longer use _puttc in all cases because I no longer use _gettc in all cases. 
        // See GetChar to know why I no longer use _gettc in all cases...
        _puttc(character, this->filePtr); // Yes ! Generic version
#else
#ifdef TOOL_UNICODE
        if (this->IsBinaryStream())
        {
            if (this->IsWideStream())
            {
                this->PutWord(character);
            }
            else
            {
                _ASSERTE(character <= 255); // Not so simple, but...
                character = TO_OS2_CHAR(character); // Keep it to remain compliant with legacy format...
                this->PutByte(character);
            }
        }
        else
        {
            // From MSDN :
            // A wide stream treats a text stream as a sequence of generalized multibyte characters,
            // which can have a broad range of encoding rules.
            // Two kinds of character conversions take place:
            // - Unicode-to-MBCS
            // - CR-LF translation
            _puttc(character, this->filePtr);
        }
#else
        if (this->IsBinaryStream()) character = TO_OS2_CHAR(character); // Keep it to remain compliant with legacy format...
        GtBool done = this->PutByte(character);
#endif
#endif

        if (this->IsError())
        {
            return Notify(GtFalse);
        }
        break;
        }
    case NullStream:
        this->count += sizeof(gtchar); // Yes !
        break;
    }
    return GtTrue; 
}


GtBool TOOL_PUBLIC PutChar(gtchar character, STREAM *stream)
{
    return stream->PutChar(character);
}


void STREAM::UngetChar(gtchar character)
{
    if (this == NULL)
    {
        return;
    }

    switch (this->type)
    { 
    case MemoryStream:
        {
#ifdef TOOL_UNICODE
        GtStringW bufW = (GtStringW)this->buf;
        --bufW;

        // To me, it sounds dangerous to store such a value in a MemoryStream.
        // Indeed, most of the time, the buffer of a MemoryStream is directly a pointer
        // to the value associated to an OBJString.
        // Normally, an unget does not modify the buffer, since you are expected to store
        // the previous value. But what happens if you do a mistake ?
        _ASSERTE(*bufW == character); // Mistake detector
        *bufW = character;

        this->buf = (gtuint8 *)bufW;
#else
        GtStringA bufA = (GtStringA)this->buf;
        --bufA;

        // To me, it sounds dangerous to store such a value in a MemoryStream.
        // Indeed, most of the time, the buffer of a MemoryStream is directly a pointer
        // to the value associated to an OBJString.
        // Normally, an unget does not modify the buffer, since you are expected to store
        // the previous value. But what happens if you do a mistake ?
        _ASSERTE(*bufA == character); // Mistake detector
        *bufA = character;

        this->buf = (gtuint8 *)bufA;
#endif
        break;
        }
    case FileStream: 
        {
#if 0
        // I no longer use _ungettc in all cases because I no longer use _gettc in all cases. 
        // See GetChar to know why I no longer use _gettc in all cases...
        _ungettc(character, this->filePtr); // Yes ! Generic version
#else
#ifdef TOOL_UNICODE
        if (this->IsBinaryStream())
        {
            if (this->IsWideStream())
            {
                this->UngetWord(character);
            }
            else
            {
                _ASSERTE(character <= 255); // Not so simple, but...
                this->UngetByte(character);
            }
        }
        else
        {
            // From MSDN :
            // A wide stream treats a text stream as a sequence of generalized multibyte characters,
            // which can have a broad range of encoding rules.
            // Two kinds of character conversions take place:
            // - Unicode-to-MBCS
            // - CR-LF translation
            _ungettc(character, this->filePtr);
        }
#else
        this->UngetByte(character);
#endif
#endif
        }
        break;
    case NullStream:
        this->count -= sizeof(gtchar); // Yes !
        break;
    }                 
}


void TOOL_PUBLIC UngetChar(gtchar character, STREAM *stream)
{
    stream->UngetChar(character);
}

/****************************************************************************/
/* Section: Reading/Writing Word */
/****************************************************************************/

GtBool STREAM::GetWord(gtuint16 *pWord)
{
    if (this == NULL) 
    {
        return Notify(GtFalse);
    }

    gtuint8 low, high;

    switch (this->type)
    { 
    case MemoryStream:
    case FileStream:   
        {
            GtBool done = (GtBool) (this->GetByte(&low) && this->GetByte(&high));
            if (done)
            {
                *pWord = MAKEUSHORT(low, high); 
                return GtTrue; 
            }
        }
        return Notify(GtFalse);
    case NullStream:
        *pWord = 0;
        return GtTrue;
    } 
    return Notify(GtFalse);               
}


GtBool TOOL_PUBLIC GetWord(gtuint16 *pWord, STREAM *stream)
{
    return stream->GetWord(pWord);
}     


GtBool STREAM::PutWord(gtuint16 word)
{
    if (this == NULL)
    {
        return Notify(GtFalse);
    }

    switch (this->type)
    { 
    case MemoryStream:
    case FileStream:
        {  
            gtuint8 low   = LOBYTE(word);
            gtuint8 high  = HIBYTE(word);

            GtBool done = (GtBool) (this->PutByte(low) && this->PutByte(high)); 

            return done;
        }
    case NullStream:
        this->count += (2 * sizeof(gtuint8));
        return GtTrue;
    } 
    return Notify(GtFalse);           
}

  
GtBool TOOL_PUBLIC PutWord(gtuint16 word, STREAM *stream)
{
    return stream->PutWord(word);
}     


void STREAM::UngetWord(gtuint16 word)
{
    if (this == NULL)
    {
        return;
    }

    switch (this->type)
    { 
    case MemoryStream:
    case FileStream:
        {  
            gtuint8 low   = LOBYTE(word);
            gtuint8 high  = HIBYTE(word);
        }
    case NullStream:
        this->count -= (2 * sizeof(gtuint8));
    }                 
}


void TOOL_PUBLIC UngetWord(gtuint16 word, STREAM *stream)
{
    stream->UngetWord(word);
}

/****************************************************************************/
/* Section: Reading/Writing Number */
/****************************************************************************/

GtBool TOOL_PUBLIC GetNum(OBJ *pObj, STREAM *stream)
{
    gtuint16 low, high;

    switch (stream->GetType())
    { 
    case STREAM::MemoryStream:
    case STREAM::FileStream:
        {
            GtBool done = (GtBool) (GetWord(&low, stream) && GetWord(&high, stream));
            if (done)
            {
                *pObj = (OBJ)MAKEULONG(low, high);
                return GtTrue; 
            }
            return Notify(GtFalse);
        }
    case STREAM::NullStream:
        *pObj = GtNil;
        return GtTrue;
    } 
    return Notify(GtFalse);         
}


GtBool TOOL_PUBLIC PutNum(OBJ obj, STREAM *stream)
{
    switch (stream->GetType())
    { 
    case STREAM::MemoryStream:
    case STREAM::FileStream:
        { 
            gtuint16 low  = LOUSHORT((gtuint32)obj);                                
            gtuint16 high = HIUSHORT((gtuint32)obj);   

            GtBool done = (GtBool) (PutWord(low, stream) && PutWord(high, stream)); 
            return done;
        }
    case STREAM::NullStream:
        return (GtBool) (PutWord(0, stream) && PutWord(0, stream)); 
    } 
    return Notify(GtFalse);        
} 


/****************************************************************************/
/* Section: Reading/Writing Real */
/****************************************************************************/

GtBool TOOL_PUBLIC GetReal(OBJ *pObj, STREAM *stream, GtBool skip)
{
    gtuint16  low1, high1, low2, high2;
    gtuint32   l1, l2, l[2];
    gtreal32  d;

    switch (stream->GetType())
    { 
    case STREAM::MemoryStream:
    case STREAM::FileStream:
        {
            GtBool done = (GtBool) (GetWord(&low1, stream) && GetWord(&high1, stream)
                                    && GetWord(&low2, stream) && GetWord(&high2, stream));
            if (done)
            {
                l1 = MAKEULONG(low1, high1);
                l2 = MAKEULONG(low2, high2);
                l[0] = l1;
                l[1] = l2;
                memmove(&d, l, sizeof(gtreal32));
                OBJ obj = Real(d);

                if (!skip)
                    *pObj = obj;
                else
                    *pObj = GtNil;

                return GtTrue; 
            }
            return Notify(GtFalse);
        }
    case STREAM::NullStream:
        *pObj = GtNil;
        return GtTrue;
    } 
    return Notify(GtFalse);         
}  


GtBool TOOL_PUBLIC PutReal(OBJ obj, STREAM *stream)
{
    gtreal32 d;
    gtuint32 l[2],l1,l2;
    gtuint16 low1, high1, low2, high2;

    switch (stream->GetType())
    { 
    case STREAM::MemoryStream:
    case STREAM::FileStream:
        { 
            d  = RealGet(obj);
            memmove(l, &d, sizeof(gtreal32));
            l1 = l[0];
            l2 = l[1];
            low1  = LOUSHORT(l1);                                
            high1 = HIUSHORT(l1);   
            low2  = LOUSHORT(l2);                                
            high2 = HIUSHORT(l2);   

            GtBool done = (GtBool) (PutWord(low1, stream) && PutWord(high1, stream)
                                && PutWord(low2, stream) && PutWord(high2, stream)); 
            return done;
        }
    case STREAM::NullStream:
        return (GtBool) (PutWord(0, stream) && PutWord(0, stream)
            && PutWord(0, stream) && PutWord(0, stream)); 
    } 
    return Notify(GtFalse);        
}  


/****************************************************************************/
/* Section: Reading/Writing Binary */
/****************************************************************************/ 

GtBool STREAM::ReadBinary (gtuint8 *buf, gtuint32 size, GtBool skip)
{
    if (this == NULL)
    {
        return Notify(GtFalse);
    }

    switch (this->type)
    { 
    case MemoryStream:
    case FileStream:         
        {          
            gtuint8 *temp = buf;
            gtuint8 byte;
            gtuint32  i; 

            for (i = 0; i < size; i++)
            {
                GtBool done = this->GetByte(&byte);
                if (!done)
                {
                    return Notify(GtFalse);
                }
                if (!skip) 
                    *temp++ = byte;
            }
            return GtTrue; 
        }
    case NullStream: 
        *buf = 0;
        return GtTrue;
    }
    return Notify(GtFalse);
}


GtBool TOOL_PUBLIC ReadBinary(/* char * */ gtuint8 *buf, gtuint32 size, STREAM *stream, GtBool skip)
{
    return stream->ReadBinary(buf, size, skip);
}  


GtBool TOOL_PUBLIC GetBinary(OBJ *pBinObj, STREAM *stream, GtBool skip)
{
    GtBool done; // Must be here otherwise VC6 complains "skipped by goto"

    OBJ    num;
    gtuint32  size;
    gtuint8 *buf; 

    GetNum(&num, stream);

    size = NumObj(num);
    CHECK (size >= 0);
    if (!skip)
    {
        *pBinObj = BinaryCreate(size);
        CHECK (*pBinObj);
        buf = BinaryPtr(*pBinObj);
    }
    done = ReadBinary(buf, size, stream, skip);
    CHECK (done);

    return GtTrue;
Overflow:
    return Notify(GtFalse);
}     


GtBool STREAM::WriteBinary(const gtuint8 *buf, gtuint32 size)
{
    if (this == NULL)
    {
        return Notify(GtFalse);
    }

    gtuint32 i;
    const gtuint8 *s = buf;

    switch (this->type)
    { 
    case MemoryStream:
    case FileStream:
        {
            for (i = 0; i < size; i++)
            {
                GtBool done = this->PutByte(*s++);
                if (!done)
                {
                    return Notify(GtFalse);
                }
            }
            return GtTrue;
        }
    case NullStream:
        this->count += (size * sizeof(gtuint8));
        return GtTrue;                
    } 
    return Notify(GtFalse);
}


GtBool TOOL_PUBLIC WriteBinary(/* char* */ const gtuint8 *buf, gtuint32 size, STREAM *stream)
{
    return stream->WriteBinary(buf, size);
}


GtBool TOOL_PUBLIC PutBinary(OBJ binObj, STREAM *stream)
{
    GtBool done; // Must be here otherwise VC6 complains "skipped by goto"

    gtuint8 *buf = BinaryPtr(binObj);
    gtuint32  size   = BinarySize(binObj);

    PutNUM(ObjNum(size), stream); 

    done = WriteBinary(buf, size, stream);

    CHECK (done);
    return GtTrue;  
Overflow:
    return Notify(GtFalse);
} 


/****************************************************************************/
/* Section: Reading/Writing String */
/****************************************************************************/

GtBool STREAM::ReadString (GtString buf, gtuint32 size, GtBool skip) // size in chars, including the final '\0'
{
    if (this == NULL) 
    {
        return Notify(GtFalse);
    }

    switch (this->type)
    { 
    case MemoryStream:
    case FileStream:         
        {          
            GtString temp = buf;
            gtchar c;
            gtuint32 i = 0; 

            do { 
                GtBool done = this->GetChar(&c);
                if (!done)
                {
                    return Notify(GtFalse);
                }
                if (!skip)
                    *temp++ = c;
                ++i;
                if ((i > size) || (i == size && c != '\0'))
                {
                    return Notify(GtFalse);
                }
            }
            while (c);

            return GtTrue; 
        }
    case NullStream: 
        *buf = 0;
        return GtTrue;
    }
    return Notify(GtFalse);
}


GtBool TOOL_PUBLIC ReadString(GtString buf, gtuint32 size, STREAM *stream, GtBool skip) // size in chars, including the final '\0'
{
    return stream->ReadString(buf, size, skip);
}  


GtBool TOOL_PUBLIC GetString(OBJ *pStrObj, STREAM *stream, GtBool skip)
{
    GtBool done; // Must be here otherwise VC6 complains "skipped by goto"

    gtuint16 size;
    GtString    buf; 

    GetWORD(&size, stream); // size in chars, including the final \0
    if (!skip)
    {
        *pStrObj = StringCreate(size); // Size in chars
        CHECK (*pStrObj);
        buf = PszOf(*pStrObj);
    }
    done = ReadString(buf, size, stream, skip);
    CHECK (done);

    return GtTrue;
Overflow:
    return Notify(GtFalse);
}     


GtBool STREAM::WriteString(GtCString string)
{
    if (this == NULL)
    {
        return Notify(GtFalse);
    }

    gtuint32 size = _tcslen(string) + 1;

    switch (this->type)
    { 
    case MemoryStream:
    case FileStream:
        {
            GtCString str = string;
            while (*string)
            {
                GtBool done = this->PutChar(*string++);
                if (!done)
                {
                    return Notify(GtFalse);
                }
            }
            GtBool done = this->PutChar(0);

            return done;
        }
    case NullStream:
        this->count += (size * sizeof(gtchar));
        return GtTrue;                
    } 
    return Notify(GtFalse);
}


GtBool TOOL_PUBLIC WriteString(GtCString string, STREAM *stream)
{
    return stream->WriteString(string);
}


GtBool TOOL_PUBLIC PutString(OBJ strObj, STREAM *stream)
{
    GtBool done; // Must be here otherwise VC6 complains "skipped by goto"

    GtString    string = PszOf(strObj);
    gtuint32 size   = _tcslen(string) + 1;

    PutWORD(size, stream); 

    done = WriteString(string, stream);
    CHECK (done);

    return GtTrue;  
Overflow:
    return Notify(GtFalse);
} 


/****************************************************************************/
/* Section: Reading/Writing array of characters */
/****************************************************************************/

GtBool STREAM::ReadCharArray(GtString buf, gtuint32 size, GtBool skip) // size in chars, no need of final '\0'
{
    if (this == NULL)
    {
        return Notify(GtFalse);
    }

    switch (this->type)
    { 
    case MemoryStream:
    case FileStream:         
        {
            GtCString str = buf;
            for (gtuint32 i=0; i < size; i++)
            {
                gtchar c;
                GtBool done = this->GetChar(&c);

                if (!done)
                {
                    return Notify(GtFalse);
                }

                if (!skip) *buf++ = c;
            }
            return GtTrue; 
        }
    case NullStream: 
        // *buf = 0; // Non sense for array of characters
        return GtTrue;
    }
    return Notify(GtFalse);
}


GtBool TOOL_PUBLIC ReadCharArray(GtString buf, gtuint32 size, STREAM *stream, GtBool skip) // size in chars, no need of final '\0'
{
    return stream->ReadCharArray(buf, size, skip);
}


GtBool STREAM::WriteCharArray(GtCString string, gtuint32 size) // Size in chars, does not append a final '\0' in the stream
{
    if (this == NULL)
    {
        return Notify(GtFalse);
    }

    switch (this->type)
    { 
    case MemoryStream:
    case FileStream:
        {
            GtCString str = string;
            for (gtuint32 i=0; i < size; i++)
            {
                GtBool done = this->PutChar(*string++);

                if (!done)
                {
                    return Notify(GtFalse);
                }
            }

            return GtTrue;
        }
    case NullStream:
        this->count += (size * sizeof(gtchar));
        return GtTrue;                
    } 
    return Notify(GtFalse);
}


GtBool TOOL_PUBLIC WriteCharArray(GtCString string, gtuint32 size, STREAM *stream) // Size in chars, does not append a final '\0' in the stream
{
    return stream->WriteCharArray(string, size);
}

