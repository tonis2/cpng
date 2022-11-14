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
    char depth;
    char color;
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

fault DataError {
    INVALID_COMPRESSION,
    INVALID_FILTER,
    UNSUPPORTED_COLOR,
    UNSUPPORTED_DEPTH,
    UNSUPPORTED_INTERLACING
}

fault FileError {
    INCORRECT_FORMAT
}

define ChunkList = List<Chunk>;

fn uint readInt(void* data, int size) {
    char[4] temp;
    libc::memcpy(&temp, data, size);
    return ((temp[0] << 24  | (int)temp[1] << 16  ) | (int)temp[2] << 8  ) | (int)temp[3];
}

fn Chunk read_chunk(char* data, uint offset) {

    uint size = readInt(data + offset, 4);

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

    int crc = readInt(data + offset + 8 + size, 4);

     // Todo implement checksum validator
     // libc::printf("crc checksum %d \n", crc);

    return Chunk {
        chunkType,
        offset,
        size 
    };
}

fn void! main() {
    File file;

    try (File.open(&file, image2, "rb"));
    try (File.seek(&file, 0, Seek.END));

    defer try (file.close());

    long size = libc::ftell(file.file);
    try (File.seek(&file, 0, Seek.SET));

    char* data = malloc(size * char.sizeof); 
    defer mem::free(data);
    libc::fread(data, 1, (int)size + 1, file.file);

    if (libc::memcmp(data, &PNG_MAGIC_BYTES, 8) != 0) {
        std::io::printf("File is not correct PNG");
        return FileError.INCORRECT_FORMAT!;
    }

    ChunkList chunks;
    defer chunks.free();
    {
        int offset = 8;

        while(true) {
            Chunk chunk = read_chunk(data, offset);

            if (chunk.type == ChunkType.ERROR) return ChunkError.FAULTY_NAME!;

            chunks.push(chunk);

            offset += (chunk.size + 12); // Size + name + content + CRC;
            if (chunk.type == ChunkType.IEND) break;
        }
    }

    Image img;

    // Parse data for the png
    
    foreach (Chunk chunk : chunks)
    {
       libc::printf("CHUNK TYPE %d \n", chunk.type);

        // Read image width, height ..etc
       if (chunk.type == ChunkType.IHDR) {
           int offset = chunk.offset + 4 + 4;
           img.width = readInt(data + offset, 4);
           offset += 4;
           img.height = readInt(data + offset , 4);
           offset += 4;

           img.depth = data[offset];
           img.color = data[offset + 1];
           img.compression = data[offset + 2];
           img.filter = data[offset + 3];
           img.interlace = data[offset + 4];

           if (img.depth != 8) {
             return DataError.UNSUPPORTED_DEPTH!;
           }

           if (img.color != 6) {
             return DataError.UNSUPPORTED_COLOR!;
           }

           if (img.compression != 0) {
             return DataError.INVALID_COMPRESSION!;
           }

           if (img.filter != 0) {
             return DataError.INVALID_FILTER!;
           }

           if (img.interlace != 0) {
             return DataError.UNSUPPORTED_INTERLACING!;
           }
       }
    }

    libc::printf("depth %d \n", img.depth);
    libc::printf("color %d \n", img.color);
    libc::printf("compression %d \n", img.compression);
    libc::printf("filter %d \n", img.filter);
    libc::printf("interlace %d \n", img.interlace);
   
    // int j;
    // for(j = 0; j < size; j++) {
    //         libc::printf("%02x ", data[j]);
    // }
    // return 0;
}