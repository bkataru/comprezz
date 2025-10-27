# Comprezz

A single-file gzip/deflate compression library for Zig, based on code from the Zig 0.14 standard library.

## Features

- **Full LZ77 + Huffman implementation** - Complete deflate algorithm implementation
- **Configurable compression levels** - Fast, default, best, and levels 4-9
- **Gzip format** - Proper headers and CRC32 checksums
- **Library + CLI** - Use as a dependency or command-line tool
- **Zero dependencies** - Self-contained implementation
- **Comprehensive tests** - All tests included in the library

## Installation

Add to your `build.zig.zon`:

```zig
.{
    .name = "your-project",
    .version = "0.1.0",
    .dependencies = .{
        .comprezz = .{
            .path = "path/to/comprezz",
        },
    },
}
```

And in your `build.zig`:

```zig
const comprezz = b.dependency("comprezz", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("comprezz", comprezz.module("comprezz"));
```

## Library Usage

### Basic Compression

```zig
const std = @import("std");
const comprezz = @import("comprezz");

pub fn main() !void {
    var buffer: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buffer);
    
    const data = "Hello, World!";
    var input = std.io.fixedBufferStream(data);
    
    try comprezz.compress(input.reader(), fbs.writer(), .{});
    
    const compressed = fbs.getWritten();
    _ = compressed;
}
```

### With Compression Level

```zig
try comprezz.compress(reader, writer, .{ .level = .best });
```

Available compression levels:
- `.fast` - Fastest compression
- `.default` - Good balance (default)
- `.best` - Best compression ratio
- `.level_4` through `.level_9` - Numeric compression levels

### Using the Compressor Type

```zig
var comp = try comprezz.compressor(writer, .{ .level = .fast });

try comp.compress(reader);
try comp.finish();
```

Or with the Writer interface:

```zig
var comp = try comprezz.compressor(writer, .{});
const w = comp.writer();
try w.writeAll("Hello, World!");
try comp.finish();
```

## CLI Usage

Build the CLI:

```bash
zig build
```

### Compress a File

```bash
comprezz input.txt -o output.gz
```

### Compression Levels

```bash
comprezz -l fast input.txt -o output.gz      # Fast compression
comprezz -l best input.txt -o output.gz      # Best compression
comprezz -l 9 input.txt -o output.gz        # Level 9
```

### From Stdin to Stdout

```bash
cat largefile.txt | comprezz > output.gz
```

### With File Input

```bash
comprezz largefile.txt > compressed.gz
```

## API Reference

### Functions

#### `compress`

```zig
pub fn compress(reader: anytype, writer: anytype, options: Options) !void
```

Compress data from a reader and write to a writer using gzip format.

- `reader`: Any reader type with `.read()` method
- `writer`: Any writer type with `.write()` method
- `options`: Compression options (level)

#### `compressor`

```zig
pub fn compressor(writer: anytype, options: Options) !Compressor(@TypeOf(writer))
```

Create a compressor instance for streaming compression.

```zig
pub fn Compressor(comptime WriterType: type) type
```

Get the Compressor type for a specific writer type.

### Compression Levels

```zig
pub const Level = enum(u4) {
    fast,     // Fastest compression
    default,  // Default balance
    best,     // Best compression
    level_4,  // Level 4
    level_5,  // Level 5
    level_6,  // Level 6
    level_7,  // Level 7
    level_8,  // Level 8
    level_9,  // Level 9
};
```

### Options

```zig
pub const Options = struct {
    level: Level = .default,
};
```

## Building

### Build the Library and CLI

```bash
zig build
```

### Run Tests

```bash
zig build test
```

### Run the CLI

```bash
zig-out/bin/comprezz --help
```

## CLI Options

```
Usage: comprezz [OPTIONS] [INPUT_FILE]

Compress files using gzip format.

Options:
  -o, --output FILE      Output file (default: stdout)
  -l, --level LEVEL      Compression level: fast, default, best, or 4-9
  -h, --help            Show this help message
  -v, --version         Show version

If no INPUT_FILE is specified, reads from stdin.

Examples:
  comprezz input.txt -o output.gz
  comprezz -l best input.txt > output.gz
  cat file.txt | comprezz > file.gz
```

## License

This code is based on the Zig 0.14 standard library, which is part of the Zig project and uses the MIT license. This implementation maintains the same license.

## Credits

- Original implementation based on Zig 0.14 standard library
- Deflate algorithm implementation inspired by zlib and Go's compress/flate
- Adapted for Zig 0.15 compatibility

## Limitations

- **Compression only**: Decompression is not implemented (removed along with compression in Zig 0.15)
- **Single-threaded**: Uses a single-threaded implementation
- **Memory usage**: Uses ~400KB of memory for the compression algorithm

## Contributing

This is a single-file library copied from Zig's standard library. For Zig language development, see [ziglang.org](https://ziglang.org/).

For issues or improvements to this specific package, please report them through appropriate channels.
