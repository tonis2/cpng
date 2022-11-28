module deflate;
import std;
import std::core::mem;
import libc;

struct BitStream {
    int currentByte;
    char* stream;
    int postion;
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
        result |= (bit << @intCast(uint, doneBits));
    }

    return result;
}

fn char getBit(uint index, int value) {
    return (index >> (value-1)) & 0x01;
}
