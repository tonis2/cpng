import std;
import std::core::mem;
import libc;
import zlib;

const char[8] PNG_MAGIC_BYTES = x"89 50 4e 47 0d 0a 1a 0a";
char[] image = "./assets/red_blue/test.png";
char[] image2 = "./assets/test.png";
char[] text = "./file.txt";

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
    PLTE,
    TRNS,
    IEND,
    ERROR,
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


fn uint readInt(void* data, int size) {
    char[4] temp;
    libc::memcpy(&temp, data, size);
    return ((temp[0] << 24  | (int)temp[1] << 16  ) | (int)temp[2] << 8  ) | (int)temp[3];
}

fn Image! parseIHDR(char* data, uint offset) {
	Image img;

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

	return img;
}

fn Chunk read_chunk(char* data, uint offset) {

    uint size = readInt(data + offset, 4);

    ChunkType chunkType = {|
        void* chunk_name = data + offset + 4;
        if (libc::strncmp(chunk_name, "IHDR", 4) == 0) {
            return ChunkType.IHDR;
        }

        if (libc::strncmp(chunk_name, "gAMA", 4) == 0) {
            return ChunkType.GAMA;
        }

        if (libc::strncmp(chunk_name, "IDAT", 4) == 0) {
            return ChunkType.IDAT;
        }

        if (libc::strncmp(chunk_name, "PLTE", 4) == 0) {
            return ChunkType.PLTE;
        }

        if (libc::strncmp(chunk_name, "tRNS", 4) == 0) {
            return ChunkType.TRNS;
        }

        if (libc::strncmp(chunk_name, "IEND", 4) == 0) {
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



    Image image_result;

	uint pixelsLen = 0;
	char* pixels;
    char* uncompressed_pixels;

    defer {
        mem::free(pixels);
        mem::free(uncompressed_pixels);
    };

    {
        int offset = 8;
        while(true) {
            
            // Read the chunks from raw bytess
            Chunk chunk = read_chunk(data, offset);

            if (chunk.type == ChunkType.IEND) break;
            if (chunk.type == ChunkType.ERROR) return ChunkError.FAULTY_NAME!;
            if (chunk.type == ChunkType.IHDR) {

               // Read image width, height ..etc
               Image! img = parseIHDR(data, chunk.offset + 4 + 4);
			   if (catch err = img) return err!;
               image_result = img;
               // Allocate data for pixels
			   pixels = malloc(img.width * img.height);
               uncompressed_pixels = malloc(img.width * img.height);
            }

            // Pixel data
            if (chunk.type == ChunkType.IDAT) {
				pixelsLen += chunk.size;
                libc::memcpy(&pixels + pixelsLen, data + offset + 8, chunk.size);
            }
                 
            // offset: type + name + size + content + CRC;
            offset += (chunk.size + 12); 
        }
    }




    // Z_stream defstream;

    // defstream.zalloc = null;
    // defstream.zfree = null;
    // defstream.opaque = null;
    // defstream.avail_in = text.len;
    // defstream.next_in = &text;
    // defstream.avail_out = 100;
    // defstream.next_out = &compressed;
    
    // zlib::deflateInit(&defstream, Z_BEST_COMPRESSION);

    // libc::printf("compression error %d \n", err);
        

    std::io::printf("depth %d \n", image_result.depth);
    std::io::printf("color %d \n", image_result.color);
    std::io::printf("compression %d \n", image_result.compression);
    std::io::printf("filter %d \n", image_result.filter);
    std::io::printf("interlace %d \n", image_result.interlace);

}
