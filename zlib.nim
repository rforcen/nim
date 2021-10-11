#  zlib wrapper, sudo apt install zlib1g-dev 

{.passL: "-lz".}

const 
  zlib_header="<zlib.h>"
  Z_OK=0

proc zlibVersion*() : cstring {.importcpp: "zlibVersion()", header: zlib_header.}

# basic raw
proc compress*(dest: cstring, destLen: ptr culong, source: cstring,  sourceLen: culong): cint {.importcpp: "compress(@)", header: zlib_header.}
proc compress2*(dest: cstring, destLen: ptr culong, source: cstring, sourceLen: culong, level:cint): cint {.importcpp: "compress2(@)", header: zlib_header.}
proc uncompress*(dest: cstring, destLen: ptr culong, source: cstring, sourceLen: culong): cint {.importcpp: "uncompress(@)", header: zlib_header.}
proc uncompress2*(dest: cstring, destLen: ptr culong, source: cstring, sourceLen: culong, level:cint): cint {.importcpp: "uncompress2(@)", header: zlib_header.}
proc compressBound*(sourceLen:culong) : culong {.importcpp: "compressBound(@)", header: zlib_header.}

# z_stream
type 
  z_stream* {.importcpp: "z_stream", header:zlib_header.} = object
  z_streamp* {.importcpp: "z_streamp", header:zlib_header.} = object

proc deflateInit*(strm: z_stream, level:cint) : cint = {.emit: "strm.zalloc = Z_NULL; strm.zfree = Z_NULL; strm.opaque = Z_NULL; result = deflateInit(&strm, level);".}
proc deflate*(strm: z_stream, flush: cint) {.importcpp: "deflate(&@)".}

# string nim wrapper
proc compress*(source: string): string =
    var
      destLen = source.len.culong
      dest = newString(compressBound(destLen))

    assert compress(dest, destLen.addr, source, source.len.culong) == Z_OK
    result = dest[0..<destLen]

proc uncompress*(source:string, len:int) : string = # len must be provided from compress source.len
  var 
    destLen=len.culong
    dest = newString(destLen)

  assert uncompress(dest, destLen.addr, source, source.len.culong) == Z_OK
  result = dest[0..<destLen]

# Compressor. seq wrapper
type Compressor[T] = object
  p : string
  clen, ulen : int # in bytes

proc compressor*[T](a : openArray[T]) : Compressor[T] =
  var 
    ulen = a.len * T.sizeof
    clen  = ulen.culong
    dest = newString(compressBound(clen))

  assert compress(dest, clen.addr, cast[cstring](a[0].unsafeAddr), clen) == Z_OK
  dest.setLen clen
  Compressor[T](p:dest, clen:clen.int, ulen:ulen.int)

proc uncompress[T](c:var Compressor[T]) : seq[T] =
  result = newSeq[T](c.ulen div T.sizeof) # size in bytes
  assert uncompress(cast[cstring](result[0].addr) , cast[ptr culong](c.ulen.unsafeAddr), c.p, c.clen.culong) == Z_OK


##################
when isMainModule:
  import strutils, times, random

  proc test_compressor =
    echo "zlib version:", zlibVersion()

    let n = 1_000_000
    var a = newSeq[float](n)

    echo "generating ", n, " floats..."

    for i, it in a.mpairs: it = (i%%1000).float #it=i.float / 100.0 + 1.0 # rand(1.0)

    echo "compressing..."
    var c = compressor[float](a)
    echo "done:", c.ulen, "/", c.clen, ", ratio:", (c.ulen / c.clen).int

    echo "uncompressing..."
    echo "done"
    assert a==c.uncompress
    echo "ok"


  proc test_zlibstring=
    var 
      source = "0123456789.".repeat(4000)
      uncmpr:string

    let 
      sourceLen=source.len
      niter=50

    echo "zlib version: ", zlibVersion()
    echo "testing string compression/decompression, w/string len:", source.len, ", iters:", niter
    let t0=now()

    for i in 0..niter:
      var dest = source.compress
      assert dest.len != 0 and dest.len < source.len
      # echo "source len:", source.len, ", compress len:", dest.len
      uncmpr=dest.uncompress sourceLen
      if i %% 100 == 0: 
        assert uncmpr.len == sourceLen and uncmpr == source
        write stdout, i, "\r"; stdout.flushFile
      #echo "uncompress len:", uncmpr.len, ", ", uncmpr[0..25], "...", uncmpr[uncmpr.len-25..<uncmpr.high]

    assert uncmpr.len == sourceLen and uncmpr == source

    echo "done in:", (now()-t0).inMilliseconds, "ms, ", "uncompress len:", uncmpr.len, ", ", uncmpr[0..25], "...", uncmpr[uncmpr.len-25..uncmpr.high]
    echo "bytes processed:", niter * sourceLen

  proc test_zlib =

    var
      source = "test string,".repeat(40)
      sourceLen = source.len

      destLen = source.len
      dest = newString(destLen)

    echo cast[int](source.addr).toHex, ", ", cast[int](dest).toHex
    var res = compress(cast[ptr cuchar](dest[0].addr), cast[ptr culong](
        destLen.addr), cast[ptr cuchar](source[0].addr), source.len.culong)
    echo "res of compress:", res, " lens:", destLen, ",", source.len
    echo dest.escape[0..<destLen], ", ", cast[int](source.addr).toHex, ", ",
        cast[int](dest).toHex

    source = newString(sourceLen)
    res = uncompress(cast[ptr cuchar](source[0].addr), cast[ptr culong](
        sourceLen.addr), cast[ptr cuchar](dest[0].unsafeAddr), destLen.culong)
    echo "res of uncompress:", res, ", len", sourceLen
    echo ", result:", source[0..15], "...", source[sourceLen-15..<sourceLen]

  proc test_zstreams=
    var 
      strm: z_stream

    echo "zlib version: ", zlibVersion()
    echo "init res: ", deflateInit(strm, 0)

  test_compressor()
  # test_zlibstring()
  # test_zstreams()
