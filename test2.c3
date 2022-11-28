import std;
import std::core::mem;
import libc;
import deflate;


fn void! main() {

    char* pixels = malloc(char.sizeof * 100);
    defer mem::free(pixels);

    pixels[0] = 1;
    pixels[1] = 2;
    pixels[3] = 3;
    
    BitStream stream = deflate::newStream(pixels);
}