# ctm wrapper

const 
  ctmlib = "libopenctm.so"
  ctmh = "<openctm.h>"

{.passL:"-l openctm".} 

type 
  CTMcontext* {.header:ctmh, importc.}= object
  CTMuint* = uint32
  CTMfloat* = float32
  CTMuintarray* = ptr UncheckedArray[CTMuint]
  CTMfloatarray* = ptr UncheckedArray[CTMfloat]

  CTMenum* = enum
    # Error codes (see ctmGetError())
    CTM_NONE              = 0x0000, #/< No error has occured (everything is OK).
                                    #/  Also used as an error return value for
                                    #/  functions that should return a CTMenum
                                    #/  value.
    CTM_INVALID_CONTEXT   = 0x0001, #/< The OpenCTM context was invalid (e.g. NULL).
    CTM_INVALID_ARGUMENT  = 0x0002, #/< A function argument was invalid.
    CTM_INVALID_OPERATION = 0x0003, #/< The operation is not allowed.
    CTM_INVALID_MESH      = 0x0004, #/< The mesh was invalid (e.g. no pvertices).
    CTM_OUT_OF_MEMORY     = 0x0005, #/< Not enough memory to proceed.
    CTM_FILE_ERROR        = 0x0006, #/< File I/O error.
    CTM_BAD_FORMAT        = 0x0007, #/< File format error (e.g. unrecognized format or corrupted file).
    CTM_LZMA_ERROR        = 0x0008, #/< An error occured within the LZMA library.
    CTM_INTERNAL_ERROR    = 0x0009, #/< An internal error occured (indicates a bug).
    CTM_UNSUPPORTED_FORMAT_VERSION = 0x000A, #/< Unsupported file format version.

    # OpenCTM context modes
    CTM_IMPORT            = 0x0101, #/< The OpenCTM context will be used for importing data.
    CTM_EXPORT            = 0x0102, #/< The OpenCTM context will be used for exporting data.

    # Compression methods
    CTM_METHOD_RAW        = 0x0201, #/< Just store the raw data.
    CTM_METHOD_MG1        = 0x0202, #/< Lossless compression (floating point).
    CTM_METHOD_MG2        = 0x0203, #/< Lossless compression (fixed point).

    # Context queries
    CTM_VERTEX_COUNT      = 0x0301, #/< Number of pvertices in the mesh (integer).
    CTM_TRIANGLE_COUNT    = 0x0302, #/< Number of triangles in the mesh (integer).
    CTM_HAS_NORMALS       = 0x0303, #/< CTM_TRUE if the mesh has normals (integer).
    CTM_UV_MAP_COUNT      = 0x0304, #/< Number of UV coordinate sets (integer).
    CTM_ATTRIB_MAP_COUNT  = 0x0305, #/< Number of custom attribute sets (integer).
    CTM_VERTEX_PRECISION  = 0x0306, #/< Vertex precision - for MG2 (float).
    CTM_NORMAL_PRECISION  = 0x0307, #/< Normal precision - for MG2 (float).
    CTM_COMPRESSION_METHOD = 0x0308, #/< Compression method (integer).
    CTM_FILE_COMMENT      = 0x0309, #/< File comment (string).

    # UV/attribute map queries
    CTM_NAME              = 0x0501, #/< Unique name (UV/attrib map string).
    CTM_FILE_NAME         = 0x0502, #/< File name reference (UV map string).
    CTM_PRECISION         = 0x0503, #/< Value precision (UV/attrib map float).

    # Array queries
    CTM_INDICES           = 0x0601, #/< Triangle pindices (integer array).
    CTM_VERTICES          = 0x0602, #/< Vertex point coordinates (float array).
    CTM_NORMALS           = 0x0603, #/< Per vertex normals (float array).
    CTM_UV_MAP_1          = 0x0700, #/< Per vertex UV map 1 (float array).
    CTM_UV_MAP_2          = 0x0701, #/< Per vertex UV map 2 (float array).
    CTM_UV_MAP_3          = 0x0702, #/< Per vertex UV map 3 (float array).
    CTM_UV_MAP_4          = 0x0703, #/< Per vertex UV map 4 (float array).
    CTM_UV_MAP_5          = 0x0704, #/< Per vertex UV map 5 (float array).
    CTM_UV_MAP_6          = 0x0705, #/< Per vertex UV map 6 (float array).
    CTM_UV_MAP_7          = 0x0706, #/< Per vertex UV map 7 (float array).
    CTM_UV_MAP_8          = 0x0707, #/< Per vertex UV map 8 (float array).
    CTM_ATTRIB_MAP_1      = 0x0800, #/< Per vertex attribute map 1 (float array).
    CTM_ATTRIB_MAP_2      = 0x0801, #/< Per vertex attribute map 2 (float array).
    CTM_ATTRIB_MAP_3      = 0x0802, #/< Per vertex attribute map 3 (float array).
    CTM_ATTRIB_MAP_4      = 0x0803, #/< Per vertex attribute map 4 (float array).
    CTM_ATTRIB_MAP_5      = 0x0804, #/< Per vertex attribute map 5 (float array).
    CTM_ATTRIB_MAP_6      = 0x0805, #/< Per vertex attribute map 6 (float array).
    CTM_ATTRIB_MAP_7      = 0x0806, #/< Per vertex attribute map 7 (float array).
    CTM_ATTRIB_MAP_8      = 0x0807  #/< Per vertex attribute map 8 (float array).

{.push header:ctmh, dynlib:ctmlib, importc.}
proc ctmNewContext*(aMode : CTMenum) : CTMcontext 
proc ctmFreeContext*(context : CTMcontext)
proc ctmGetError*(context : CTMcontext) : CTMenum
proc ctmErrorString*(prop:CTMenum) : cstring
proc ctmGetInteger*(context : CTMcontext, prop: CTMenum) : CTMuint
proc ctmGetFloat*(context : CTMcontext, prop: CTMenum) : CTMfloat
proc ctmGetFloatArray*(context : CTMcontext, prop: CTMenum) : ptr CTMfloat
proc ctmGetIntegerArray*(context : CTMcontext, prop: CTMenum) : ptr CTMuint
proc ctmGetNamedUVMap*(aContext:CTMcontext, aName:cstring) : CTMenum
proc ctmGetUVMapString*(aContext:CTMcontext, aUVMap:CTMenum, aProperty:CTMenum) : cstring
proc ctmGetUVMapFloat*(aContext:CTMcontext, aUVMap:CTMenum, aProperty:CTMenum) : CTMfloat
proc ctmGetNamedAttribMap*(aContext:CTMcontext, aName:cstring):CTMenum
proc ctmGetAttribMapString*(aContext:CTMcontext, aAttribMap:CTMenum, aProperty:CTMenum) : cstring
proc ctmGetAttribMapFloat*(aContext:CTMcontext , aAttribMap:CTMenum, aProperty:CTMenum) : CTMfloat 
proc ctmGetString*(aContext:CTMcontext ,  aProperty:CTMenum):cstring
proc ctmCompressionMethod*(aContext:CTMcontext, aMethod:CTMenum)
proc ctmCompressionLevel*(aContext:CTMcontext, aLevel:CTMuint)
proc ctmVertexPrecision*(aContext:CTMcontext, aPrecision:CTMfloat)
proc ctmVertexPrecisionRel*(aContext:CTMcontext, aPrecisionRel:CTMfloat)
proc ctmNormalPrecision*(aContext:CTMcontext, aPrecision:CTMfloat)
proc ctmUVCoordPrecision*(aContext:CTMcontext, aUVMap:CTMenum , aPrecision:CTMfloat)
proc ctmAttribPrecision*(aContext:CTMcontext, aAttribMap:CTMenum , aPrecision:CTMfloat)
proc ctmFileComment*(aContext:CTMcontext , aFileComment:cstring)
proc ctmAddUVMap*(aContext:CTMcontext, aUVCoords: ptr CTMfloat, aName:cstring, aFileName:cstring):CTMenum 
proc ctmAddAttribMap*(aContext:CTMcontext, aAttribValues: ptr  CTMfloat, aName:cstring):CTMenum 
proc ctmDefineMesh*(aContext:CTMcontext, aVertices : ptr CTMfloat, aVertexCount:CTMuint, aIndices : ptr CTMuint,
  aTriangleCount:CTMuint, aNormals:ptr CTMfloat)

proc ctmLoad*(context : CTMcontext, file_name : cstring)
proc ctmSave*(aContext:CTMcontext , aFileName : cstring)
{.pop.}





####################
# when isMainModule:
#   proc test_rw=
#     var mesh = loadCTM("pisc.ctm")
#     echo if mesh.check: "read ok" else: "bad mesh"
#     mesh.saveCTM("piscsaved.ctm")
#     mesh=loadCTM("piscsaved.ctm")
#     echo "#vertices:", mesh.shape.len, ", #faces:",mesh.trigs.len

#   proc test_cd=
#     for i in countup(0,6-1,3):
#       echo i, i+1, i+2

#   test_rw()