fault ParseError
{
    InvalidDeflateStream,
    Unsupported,
    StreamEmpty
}

struct BitStream {
   []char stream;
   uint index;
   uint bitPosition; 
}

fn char! BitStream.nextByte(BitStream* this) {
     if (this.stream.len == 0) {
          return ParseError.StreamEmpty!;
      }
}

fn []char! decompress([]char data) {

}