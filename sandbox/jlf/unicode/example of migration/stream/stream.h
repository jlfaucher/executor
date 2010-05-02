class TOOL_PUBLIC STREAM
{
public:
  STREAM();
  STREAM(gtuint8 *buf, gtuint32 size); // size in bytes
  STREAM(gtuint8 *buf, gtuint32 size, GtBool privateClipboard); // size in bytes
  STREAM(GtCString fileName, GtCString mode, GtBool &ok);
  STREAM(GtCString fileName, GtCString mode, GtBool privateClipboard, GtBool &ok);

  ~STREAM();

  GtBool CloseStream();

  typedef enum {FileStream, MemoryStream, NullStream} StreamType;
  StreamType GetType();

  GtBool IsPrivateClipboard();

  // Can't be both, of course
  GtBool IsTextStream();
  GtBool IsBinaryStream();
  
  // Can't be both, of course
  GtBool IsByteStream();
  GtBool IsWideStream();

  gtint32 GetCount();

  GtBool SetFmt(int value);

  int IsError();
  int IsEof();

  gtuint32 GetPos(); // Like ftell
  GtBool SetPos(gtuint32 pos); // Like fseek

  GtBool GetByte(gtuint8 *pByte);        
  GtBool PutByte(gtuint8 byte);
  void UngetByte(gtuint8 byte);

  GtBool GetChar(gtchar *pCharacter);        
  GtBool PutChar(gtchar character);
  void UngetChar(gtchar character);

  GtBool GetWord(gtuint16 *pWord);
  GtBool PutWord(gtuint16 word);
  void UngetWord(gtuint16 word);

  GtBool WriteString(GtCString string); // Appends a final '\0' in the stream
  GtBool ReadString (GtString buf, gtuint32 size, GtBool skip); // size in chars, including the final '\0'

  // Unlike Write|ReadString, those methods do not depend on a final '\0'
  // I need them to replace the calls to fwrite and fread when appropriate.
  GtBool WriteCharArray(GtCString string, gtuint32 size); // Does not append a final '\0' in the stream
  GtBool ReadCharArray(GtString buf, gtuint32 size, GtBool skip); // size in chars, no need of final '\0'

  GtBool WriteBinary(const gtuint8 *buf, gtuint32 size); // size in bytes
  GtBool ReadBinary (gtuint8 *buf, gtuint32 size, GtBool skip); // size in bytes

  void ClosePrivateClipboard();

public:
  static GtCString StreamType2String(StreamType type);

private:
  void Constructor(gtuint8 *buf, gtuint32 size); // size in bytes
  void Constructor(GtCString fileName, GtCString mode, GtBool &ok);

  StreamType  type;
  FILE        *filePtr;
  gtuint8     *buf;
  gtuint8     *bufStart; // just to be able to check that the parameter passed to SetPos is valid.
  gtuint8     *bufEnd;
  gtint32     count;
  GtBool      isPrivateClipboard;
  int         fmt;
  gtuint8     *start;

  GtBool isTextStream; // If not text, then binary
  
  GtBool isByteStream; // If not byte, then wide
};

