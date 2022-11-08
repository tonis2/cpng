import std;
import std::core::mem;
import libc;
import std::array::list;

const char[8] PNG_MAGIC_BYTES = x"89 50 4e 47 0d 0a 1a 0a";
char[] image = "./assets/red_blue/test.png";
char[] image2 = "./assets/test.png";
char[] text = "./file.txt";

struct Image {
    uint width;
    uint height;
    char bitdepth;
    char colordepth;
    char compression;
    char filter;
    char interlace;
}


enum ChunkType {
    IHDR,
    GAMA,
    IDAT,
    IEND,
    ERROR
}

enum ImageType {
    GRAYSCALE,
    TRUECOLOR,
    INDEXEDCOLOR,
    GREYSCALE_A,
    TRUECOLOR_A
}

struct Chunk {
    ChunkType type;
    int offset;
    int size;
}

fault ChunkError
{
    FAULTY_NAME,
    CORRUPT_DATA,
}

define ChunkList = List<Chunk>;

fn Chunk! read_chunk(char* data, uint offset) {

    int size = {|
        char[4] temp;
        libc::memcpy(&temp, data + offset, 4);
        return ((temp[0] << 24  | (int)temp[1] << 16  ) | (int)temp[2] << 8  ) | (int)temp[3] ;
    |};

    ChunkType chunkType = {|
        if (libc::strncmp(data + offset + 4, "IHDR", 4) == 0) {
            return ChunkType.IHDR;
        }

        if (libc::strncmp(data + offset + 4, "gAMA", 4) == 0) {
            return ChunkType.GAMA;
        }

        if (libc::strncmp(data + offset + 4, "IDAT", 4) == 0) {
            return ChunkType.IDAT;
        }

        if (libc::strncmp(data + offset + 4, "IEND", 4) == 0) {
            return ChunkType.IEND;
        }

        return ChunkType.ERROR;
    |};
  
    if (chunkType == ChunkType.ERROR) {
        return ChunkError.FAULTY_NAME!;
    };
   
    // char[] content = data[(offset + 8) .. (offset + 8 + size)];
      
    int crc = {|
        char[4] temp;
        libc::memcpy(&temp, data + offset + 8 + size, 4);
        return ((temp[0] << 24  | (int)temp[1] << 16  ) | (int)temp[2] << 8  ) | (int)temp[3];
    |};

     // Todo implement checksum validator
    //  libc::printf("crc checksum %d \n", crc);

    return Chunk {
        chunkType,
        offset,
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

    ChunkList chunks;
    defer chunks.free();

    int offset = 8;

    while(true) {
        Chunk! chunk = read_chunk(data, offset);

        if (catch chunk) return 5;
        chunks.push(chunk);
        
        offset += chunk.size;
        if (chunk.type == ChunkType.IEND) break;
    }

    foreach (Chunk x : chunks)
    {
       libc::printf("CHUNK TYPE %d \n", x.type);
    }
    // int j;
    // for(j = 0; j < size; j++) {
    //         libc::printf("%02x ", data[j]);
    // }
    return 0;
}