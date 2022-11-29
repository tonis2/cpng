module deflate;
import std;
import std::core::mem;
import libc;

struct BitStream {
    char* buffer;
    char bits;
    int first_read;
    int position;
}

fn BitStream newStream(char* data) {
    BitStream stream = BitStream{data, 0, 0, 0};
    return stream;
}

fn int* BitStream.getNBits(BitStream* self, uint size) {
     int i;
     int *bin = malloc(size * int.sizeof);

     for (i = 0; i < size; i++) {
        if (!self.first_read || self.position == char.sizeof) {
            self.first_read = 1;
            self.position = 0;
        }

        int shift_pos = (int)char.sizeof - self.position - 1;
        bin[i] = (self.bits >> shift_pos) & 1;
        self.position ++;
     }

    return bin;
}

// fn char getBit(uint index, char* value) {
//     return (index >> (value-1)) & 0x01;
// }
