# cifar dataset reader

#[
Binary version
The binary version contains the files data_batch_1.bin, data_batch_2.bin, ..., data_batch_5.bin, as well as test_batch.bin. Each of these files is formatted as follows:

<1 x label><3072 x pixel>
...
<1 x label><3072 x pixel>

In other words, the first byte is the label of the first image, which is a number in the range 0-9. The next 3072 bytes are the values of the pixels of the image. 
The first 1024 bytes are the red channel values, the next 1024 the green, and the final 1024 the blue. 
The values are stored in row-major order, so the first 32 bytes are the red channel values of the first row of the image.

Each file contains 10000 such 3073-byte "rows" of images, although there is nothing delimiting the rows. 
Therefore each file should be exactly 30730000 bytes long.

There is another file, called batches.meta.txt. This is an ASCII file that maps numeric labels in the range 0-9 to meaningful class names. 
It is merely a list of the 10 class names, one per row. The class name on row i corresponds to numeric label i.   
]#

from mat import vec

const 
  path = "cifar/cifar-10-batches-bin/"
  base_name = "data_batch_" # 1..5
  n_recs* = 10000 # in a file
  n_files* = 5
  total_recs* = n_recs * n_files
  image_width* = 32
  image_size* = image_width * image_width
  img_nbytes* = image_size * 3 # rgb per pixel

  n_labels* = 10
  meta_images* = ["airplane","automobile","bird","cat","deer","dog","frog","horse","ship","truck"]

type
  Image* = array[img_nbytes, uint8]
  ImageFloat* = array[image_size, float32]

  CifarRec* = object
    label* : int8
    image* : Image

  Cifar* = object
    training* : ptr array[n_recs * n_files, CifarRec]
    test*: ptr array[n_recs, CifarRec]

proc load_cifar*() : Cifar =
  var sbuff : string
  for i in 1..5:
    sbuff.add readFile(path & base_name & $i & ".bin")
  result.training = cast[ptr array[n_recs * n_files, CifarRec]](sbuff[0].addr)

  sbuff = readFile(path & "test_batch.bin")
  result.test = cast[ptr array[n_recs, CifarRec]](sbuff[0].addr)

converter img_to_vec*(img : Image) : vec = # rgb -> 0..1
  for i in 0..<image_size:
    result.add (img[i].int32 or (img[i + image_size].int32.shl 8) or (img[i + image_size*2].int32.shl 16)).float32 / 0x00ff_ffff.float32

converter lbl_to_vec*(lbl : int8) : vec = # [10]
  result = newSeq[float32](10)
  result[lbl]=1

proc get_label*(ix:int8):string = meta_images[ix]
func ntest*(c:Cifar) : int = n_recs
func ntrain*(c:Cifar) : int = total_recs

proc check*(c:Cifar)=
  for r in 0..<total_recs: # training data
    let 
      d = c.training[r]
      lbl = d.label
      img = d.image
    assert lbl in 0..9
    let _ = get_label(lbl)
    let fa : vec = img
    for f in fa:
      assert f in 0.0 .. 1.0

  for r in 0..<n_recs: # test data
    let 
      d = c.test[r]
      lbl = d.label
      img = d.image
    assert lbl in 0..9
    let _ = get_label(lbl)

    let fa : vec = img
    for f in fa:
      assert f in 0.0 .. 1.0


when isMainModule:
  echo "Cifar loading..."
  let cifar = load_cifar()
  echo "checking..."
  cifar.check
  echo "ok, size:", cifar.training[].sizeof, " bytes"
