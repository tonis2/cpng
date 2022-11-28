module deflate;
import std;
import std::core::mem;
import libc;

struct BitStream {
    int currentByte;
    char* stream;
    int position;
}

fn BitStream newStream(char* data) {
    BitStream stream = BitStream{0, data, 0};
    return stream;
}

fn uint BitStream.getNBits(BitStream* self, uint value) {
    uint result;
    uint doneBits = 0;

    while(doneBits == value) {
        char bit = getBit(self.position + 1, self.stream);
        result |= ((uint)bit << doneBits);
        self.position += 1;


        // if (self.bitPosition == 8) {
        //     self.currentByte = self.getNextByte();
        //     self.bitPosition = 0;
        // }
    }

    return result;
}

fn char getBit(uint index, char* value) {
    return (index >> (value-1)) & 0x01;
}
