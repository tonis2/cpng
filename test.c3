import std;
import std::core::mem;
import libc;

// fn char[] read4Bytes(char* buffer, int index) {
//     return buffer[index..(index + 4)];
// }

const char[8] PNG_MAGIC_BYTES = x"89 50 4e 47 0d 0a 1a 0a";
char[] image = "./assets/red_blue/test.png";
char[] text = "./file.txt";


enum ChunkType {
    IHDR,
    GAMA,
    IDAT,
    IEND
}

struct Chunk {
    ChunkType chunk;
    char[] data;
    uint size;
}

fn void read_chunk(char* data, uint offset) {
    

    // Parse big endian size bytes
    int size = (data[offset] | ( (int)data[offset + 1] << 8 ) | ( (int)data[offset + 2] << 16 ) | ( (int)data[offset + 3] << 24 ));
    char[] chunkType = data[(offset + 4).. (offset + 8)];
    // char[] content = bytes[(offset + 7)..size];
    // libc::printf("%d \n", size);
    libc::printf("%s \n", chunkType);
}

fn int main() {
    File file;

    try (File.open(&file, image, "rb"));
    try (File.seek(&file, 0, Seek.END));

    defer try (file.close());

    long size = libc::ftell(file.file);
    std::io::printf("file size %d \n", size);

    try (File.seek(&file, 0, Seek.SET));

    char* data = malloc(size * char.sizeof);
    defer mem::free(data);
    libc::fread(data, 1, (int)size + 1, file.file);

    if(libc::memcmp(data[0..8], &PNG_MAGIC_BYTES, 8) != 0) {
        std::io::printf("File is not correct PNG");
        return 1;
    }

    read_chunk(data, PNG_MAGIC_BYTES.len);
    // int j;
    // for(j = 0; j < size; j++) {
    //         libc::printf("%02x ", data[j]);
    // }
    return 0;
}