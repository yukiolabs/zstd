const std = @import("std");
const log = std.log.scoped(.zstd);

const c = @cImport({
    @cInclude("zstd.h");
});

//returns the worst case size needed for a destination buffer,
// which can be used to preallocate a destination buffer or select a previously
// allocated buffer from a pool.
// See zstd.h to mirror implementation of ZSTD_COMPRESSBOUN
pub fn compress_bound(src_size: usize) usize {
    const low_limit: usize = 128 << 10;
    var margin: usize = 0;
    if (src_size < low_limit) {
        margin = (low_limit - src_size) >> 11;
    }
    return src_size + (src_size >> 8) + margin;
}

pub fn compress(a: std.mem.Allocator, src: []const u8) ![]u8 {
    return compress_level(a, src, 20);
}

pub fn compress_level(a: std.mem.Allocator, src: []const u8, level: c_int) ![]u8 {
    var os = std.ArrayList(u8).init(a);
    try compress_level_buffer(&os, src, level);
    return os.toOwnedSlice();
}

pub fn compress_level_buffer(os: *std.ArrayList(u8), src: []const u8, level: c_int) !void {
    const bound = compress_bound(src.len);
    try os.resize(bound);
    const compressed_size = c.ZSTD_compress(
        os.items.ptr,
        os.items.len,
        src.ptr,
        src.len,
        level,
    );
    const size = @intCast(usize, compressed_size);
    if (is_error(size)) {
        const name = c.ZSTD_getErrorName(size);
        log.err("failed to compress data_size={} code={} name={s}", .{
            src.len,
            size,
            @ptrCast([*:0]const u8, name),
        });
        return error.ZSTDErrror;
    }
    try os.resize(size);
}

pub fn decompress(a: std.mem.Allocator, src: []const u8) ![]const u8 {
    var os = std.ArrayList(u8).init(a);
    try decompress_buffer(&os, src);
    return os.toOwnedSlice();
}

pub fn decompress_buffer(os: *std.ArrayList(u8), src: []const u8) !void {
    const size = @intCast(usize, c.ZSTD_getFrameContentSize(
        src.ptr,
        src.len,
    ));
    if (is_error(size)) {
        const name = c.ZSTD_getErrorName(size);
        log.err("failed to decompress  code={} name={s}", .{
            size,
            @ptrCast([*:0]const u8, name),
        });
        return error.ZSTDErrror;
    }
    if (size > 0) {
        try os.resize(size);
    } else {
        try os.resize(src.len * 3);
    }

    var i: usize = 0;
    while (i < 3) : (i += 1) {
        const written = c.ZSTD_decompress(
            os.items.ptr,
            os.items.len,
            src.ptr,
            src.len,
        );
        const decompressed_size = @intCast(usize, written);
        if (is_size_too_small(decompressed_size)) {
            try os.resize(os.items.len * 2);
        } else {
            try os.resize(decompressed_size);
            return;
        }
    }
    return error.FailedToAllocateBuffer;
}

fn is_error(code: usize) bool {
    return c.ZSTD_isError(code) != 0;
}

const err_size_too_small = "Destination buffer is too small";

fn is_size_too_small(code: usize) bool {
    if (is_error(code)) {
        const name = std.mem.toBytes(c.ZSTD_getErrorName(code));
        return std.mem.eql(u8, name[0..], err_size_too_small);
    }
    return false;
}

test "ZSTD compress and decompress" {
    const text = "hello, world";
    var a = try compress(std.testing.allocator, text);
    var b = try decompress(std.testing.allocator, a);
    defer std.testing.allocator.free(a);
    defer std.testing.allocator.free(b);

    try std.testing.expectEqualStrings(text, b);
}
