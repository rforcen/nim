#  libarchive wrapper, requires cpp backend

{.passL: "-larchive".}

# libarchive wrapper

const
  BufferSize = 16 * 1024 # 16k

  ARCHIVE_EOF* = 1       # Found end of archive.
  ARCHIVE_OK* = 0        # Operation was successful.
  ARCHIVE_RETRY* = -10   # Retry might succeed.
  ARCHIVE_WARN* = -20 # Partial success.  For example, if write_header "fails", then you can't push data.
  ARCHIVE_FAILED* = -25 # Current operation cannot complete.  But if write_header is "fatal," then this archive is dead and useless.
  ARCHIVE_FATAL* = -30   # No more operations are possible.

type
  cArchive* {.importcpp: "archive", header: "<archive.h>".} = object
  cEntry* {.importcpp: "archive_entry", header: "<archive_entry.h>".} = object

proc archive_read_new*(): ptr cArchive {.importcpp: "archive_read_new()".}
proc archive_read_support_format_all*(arch: ptr cArchive) {.
    importcpp: "archive_read_support_format_all(@)".}
proc archive_read_support_filter_all*(arch: ptr cArchive) {.
    importcpp: "archive_read_support_filter_all(@)".}
proc archive_read_open_filename*(arch: ptr cArchive, name: cstring,
    buffsize: csize_t): cint {.importcpp: "archive_read_open_filename(#,@)".}
proc archive_read_close*(arch: ptr cArchive) {.
    importcpp: "archive_read_close(@)".}
proc archive_read_free*(arch: ptr cArchive) {.
    importcpp: "archive_read_free(@)".}
proc archive_read_next_header*(arch: ptr cArchive,
    entry: ptr ptr cEntry): cint {.importcpp: "archive_read_next_header(#,@)".}
proc archive_entry_pathname*(entry: ptr cEntry): cstring {.
    importcpp: "archive_entry_pathname(@)".}
proc archive_entry_size*(entry: ptr cEntry): int64 {.
    importcpp: "archive_entry_size(@)".}
proc archive_read_data*(arch: ptr cArchive, buff: pointer,
    size: csize_t): csize_t {.importcpp: "archive_read_data(@)".}

# nim Archive

type
  Archive* = object
    carch: ptr cArchive
    centry: ptr cEntry
    buff: string
    name: string
    path: string
    size: int
    counter: int

  StatusHeader* = enum
    stOK
    stEOF
    stSKIP
    stERROR

proc archive*: Archive =
  var carch: ptr cArchive = archive_read_new()

  assert carch != nil

  archive_read_support_format_all(carch)
  archive_read_support_filter_all(carch)
  Archive(carch: carch, centry: nil)

proc open*(arch: var Archive, name: string): bool =
  archive_read_open_filename(arch.carch, name, BufferSize) == ARCHIVE_OK

proc next*(arch: var Archive): StatusHeader =
  let r = archive_read_next_header(arch.carch, arch.centry.addr)
  if r == ARCHIVE_EOF: result = stEOF
  elif r < ARCHIVE_OK or r < ARCHIVE_WARN: result = stERROR
  else:
    arch.path = $archive_entry_pathname(arch.centry)
    arch.size = archive_entry_size(arch.centry).int
    arch.counter.inc

    result = stOK

proc read*(arch: var Archive): bool =
  if arch.size != 0: # from 'next'
    arch.buff = newString(arch.size.csize_t)
    archive_read_data(arch.carch, arch.buff[0].addr, arch.size.csize_t) ==
        arch.size.csize_t
  else: false

proc close*(arch: var Archive) =
  archive_read_close(arch.carch)
  archive_read_free(arch.carch)

#########
when isMainModule:
  import strutils, re, times

  proc test_archive = #noaa all station file
    var arch = archive() # init
    var
      counter = 0
      bytes = 0
      pool: seq[string]
    let pool_size = 8*10

    let t0 = now()
    if arch.open("/home/asd/Documents/noaa_data/ghcnd_all.tar.gz"):
      while arch.next() == stOK: # two uppercase letters->country, 9 chars
        if (arch.path.match re"ghcnd_all/[A-Z]{2}\S{9}\.dly") and arch.read():
          if counter %% 1000 == 0:
            write stdout, "\r ", counter, ": path: ", arch.path, ", size: ",
                arch.size, ", data: ", arch.buff[0..60]; stdout.flushFile

          if pool.len == pool_size:
            pool = @[]
          else:
            pool.add(arch.buff)

          counter.inc
          bytes+=arch.size
      arch.close

      echo "\nlap:", (now()-t0).inSeconds, "sec, ", counter, " files, ", bytes, " bytes"

  proc test_c_raw_archive =
    var arch: ptr cArchive = archive_read_new()
    echo "arch ptr=", cast[int](arch).toHex
    archive_read_support_format_all(arch)
    archive_read_support_filter_all(arch)

    var res = archive_read_open_filename(arch,
        "/home/asd/Documents/noaa_data/ghcnd_all.tar.gz", BufferSize)
    echo "open res ok?:", res == ARCHIVE_OK

    var entry: ptr cEntry

    for i in 0..10:
      res = archive_read_next_header(arch, entry.addr)
      let size = archive_entry_size(entry)
      echo "header ok:", res == ARCHIVE_OK, ", name=", archive_entry_pathname(
          entry), ", size:", size
      if size > 0:
        let buff = newString(size)
        echo "  read ", archive_read_data(arch, buff[0].unsafeAddr,
            size.csize_t), " bytes"
        echo buff[0..80]

    archive_read_close(arch)
    archive_read_free(arch)

    echo "closed, ok"

  test_archive()
