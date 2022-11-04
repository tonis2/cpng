import std;
import std::core::mem;
import libc;

// fn char[] read4Bytes(char* buffer, int index) {
//     return buffer[index..(index + 4)];
// }

const char[8] PNG_MAGIC_BYTES = x"89 50 4e 47 0d 0a 1a 0a";
char[] image = "./assets/red_blue/test.png";
char[] image2 = "./assets/test.png";
char[] text = "./file.txt";


enum ChunkType {
    IHDR,
    GAMA,
    IDAT,
    IEND,
    ERROR
}

struct Chunk {
    ChunkType type;
    char[] data;
    int crc;
    int size;
}

fn Chunk read_chunk(char* data, uint offset) {
    libc::printf("OFFSET %d \n", offset);

    // Parse size bytes
    char[4] temp;
    libc::memcpy(data + offset, &temp, 4);
    int size = bitcast(temp, int);
    libc::printf("size %d \n", size);
    ChunkType chunkType = {|
        char[] name = data[(offset + 4).. (offset + 8)]; 
        libc::printf("TYPE %s \n", name);
        if (libc::strcmp(name, "IHDR") == 0) {
            return ChunkType.IHDR;
        }

        if (libc::strcmp(name, "GAMA") == 0) {
            return ChunkType.GAMA;
        }

        if (libc::strcmp(name, "IDAT") == 0) {
            return ChunkType.IDAT;
        }

        if (libc::strcmp(name, "IEND") == 0) {
            return ChunkType.IEND;
        }

        libc::printf("CHUNK ERROR TYPE %s \n", name);
        return ChunkType.ERROR;
    |};

    char[] content = data[(offset + 8) .. (offset + 8 + size)];
    
    libc::memcpy(data + offset + content.len, &temp, 4);
    int crc = bitcast(temp, int);

    libc::printf("CRC %d \n", crc);
    return Chunk {
        chunkType,
        content,
        crc,
        4 + 4 + size + 4 // Size + name + content + CRC
    };
}

fn int main() {
    File file;

    try (File.open(&file, image2, "rb"));
    try (File.seek(&file, 0, Seek.END));

    defer try (file.close());

    long size = libc::ftell(file.file);
    try (File.seek(&file, 0, Seek.SET));

    char* data = malloc(size * char.sizeof);
    defer mem::free(data);
    libc::fread(data, 1, (int)size + 1, file.file);

    if(libc::memcmp(data[0..8], &PNG_MAGIC_BYTES, 8) != 0) {
        std::io::printf("File is not correct PNG");
        return 1;
    }
    // Chunk chunk = read_chunk(data, 8);
    int offset = 8;
    while(true) {
        Chunk chunk = read_chunk(data, offset);
        offset += chunk.size;

        if (chunk.type == ChunkType.IEND) break;
        if (offset > 40) break;
    }
    // int j;
    // for(j = 0; j < size; j++) {
    //         libc::printf("%02x ", data[j]);
    // }
    return 0;
}