const std = @import("std");

pub fn add(
    comptime zstd_src: []const u8,
    exe: *std.build.LibExeObjStep,
) void {
    const include_dirs = &[_][]const u8{
        //zstd
        zstd_src ++ "/lib",
        zstd_src ++ "/lib/common",
        zstd_src ++ "/lib/common/portability_macros.h",
        zstd_src ++ "/lib/compress",
        zstd_src ++ "/lib/decompress",
    };
    for (include_dirs) |dir| {
        exe.addIncludePath(dir);
    }
    const sources = &[_][]const u8{
        //zstd
        zstd_src ++ "/lib/common/debug.c",
        zstd_src ++ "/lib/common/entropy_common.c",
        zstd_src ++ "/lib/common/error_private.c",
        zstd_src ++ "/lib/common/fse_decompress.c",
        zstd_src ++ "/lib/common/pool.c",
        zstd_src ++ "/lib/common/threading.c",
        zstd_src ++ "/lib/common/xxhash.c",
        zstd_src ++ "/lib/common/zstd_common.c",

        zstd_src ++ "/lib/compress/fse_compress.c",
        zstd_src ++ "/lib/compress/hist.c",
        zstd_src ++ "/lib/compress/huf_compress.c",
        zstd_src ++ "/lib/compress/zstd_compress.c",
        zstd_src ++ "/lib/compress/zstd_compress_literals.c",
        zstd_src ++ "/lib/compress/zstd_compress_sequences.c",
        zstd_src ++ "/lib/compress/zstd_compress_superblock.c",
        zstd_src ++ "/lib/compress/zstd_double_fast.c",
        zstd_src ++ "/lib/compress/zstd_fast.c",
        zstd_src ++ "/lib/compress/zstd_lazy.c",
        zstd_src ++ "/lib/compress/zstd_ldm.c",
        zstd_src ++ "/lib/compress/zstdmt_compress.c",
        zstd_src ++ "/lib/compress/zstd_opt.c",

        zstd_src ++ "/lib/decompress/huf_decompress_amd64.S",
        zstd_src ++ "/lib/decompress/huf_decompress.c",
        zstd_src ++ "/lib/decompress/zstd_ddict.c",
        zstd_src ++ "/lib/decompress/zstd_decompress_block.c",
        zstd_src ++ "/lib/decompress/zstd_decompress.c",
    };

    // we build single threaded
    exe.addCSourceFiles(sources, &[_][]const u8{
        // "-DZSTD_DISABLE_ASM",
    });
}
