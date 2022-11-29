import std;
import std::core::mem;
import libc;
import deflate;

fn int isBitSet(int val) {
    return (val) & (1 << (0));
}

fn void! main() {

    char* pixels = malloc(char.sizeof * 100);
    defer mem::free(pixels);

    pixels[0] = 1;
    pixels[1] = 2;
    pixels[3] = 3;
    
    BitStream stream = deflate::newStream(pixels);
    int* bits = stream.getNBits(3);

    defer mem::free(bits);
    char[*] bytes = x'01 00 11';
    std::io::printf("bit value %x ", bytes[1]);
}