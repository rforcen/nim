# mnist reader

import streams, endians, sequtils, random
import mat

{.experimental: "parallel".}

const 
  path="data/"

  tr_img="train-images-idx3-ubyte"
  tr_lbl="train-labels-idx1-ubyte"

  te_img="t10k-images-idx3-ubyte"
  te_lbl="t10k-labels-idx1-ubyte"

const 
  tInput* = 0 # images 784 image 0..1
  tOutput* = 1 # labels array[10] w/ 1 in position

type

  Training* = array[2,vvec] # [imgs, labels]
  file_types = enum tLabel = 2049, tImage = 2051


  MNISTfile=object
    stm : Stream
    offset : int32
    magic, nItems, rows, cols, imgSize : int32
    imgBuff : seq[uint8]
    ok : bool

  MNIST* = object
    tr_img, tr_lbl, te_img, te_lbl : MNISTfile

## MNISTfile

proc readi32(stm:Stream) : int32 = 
  discard stm.readData(result.addr, int32.sizeof)
  swapEndian32(result.addr, result.addr)

proc mnist_img*(name:string) : MNISTfile =
  result.stm = newFileStream(name, fmRead)
  assert result.stm.isNil == false
  result.magic = result.stm.readi32
  assert result.magic == tImage.int32
  result.n_items = result.stm.readi32
  result.offset = 4 + 4 + 4 + 4
  result.cols = result.stm.readi32
  result.rows = result.stm.readi32
  assert result.cols!=0  and result.rows!=0
  result.imgSize = result.cols * result.rows
  result.imgBuff = newSeq[uint8](result.imgSize)
  result.ok=true

proc mnist_lbl*(name:string) : MNISTfile =
  result.stm = newFileStream(name, fmRead)
  assert result.stm.isNil == false
  result.magic = result.stm.readi32
  assert result.magic == tLabel.int32
  result.n_items = result.stm.readi32
  assert result.n_items != 0
  result.offset = 4 + 4
  result.ok=true

proc get_byte(m : MNISTfile, item : int) : uint8 =
  assert m.magic == tLabel.int32
  m.stm.setPosition m.offset + item
  result = m.stm.peekUint8

proc read_image(m : var MNISTfile, item : int) =
  assert m.magic == tImage.int32
  m.stm.setPosition m.offset + item * m.imgSize
  assert m.stm.readData(m.imgBuff[0].addr,  m.imgSize) == m.imgSize

proc to_input_seq(m : MNISTfile) : seq[real] =
  assert m.magic == tImage.int32
  result = newSeq[real](m.imgSize)
  for i, b in m.imgBuff.pairs:
    result[i] = b.real / 255

proc to_input_seq(m : var MNISTfile, i : int) : seq[real] =
  m.read_image(i)
  m.to_input_seq()

proc get_label_seq(m : MNISTfile, i : int) : seq[real] =
  result = newSeq[real](10)
  result[ m.get_byte(i) ] = 1

## MNIST

proc `=destroy`(m: var MNIST)=
  if not m.tr_img.stm.isNil: m.tr_img.stm.close
  if not m.tr_lbl.stm.isNil: m.tr_lbl.stm.close
  if not m.te_img.stm.isNil: m.te_img.stm.close
  if not m.te_lbl.stm.isNil: m.te_lbl.stm.close

proc newMNIST* : MNIST =
  MNIST(tr_img : mnist_img(path & tr_img), tr_lbl : mnist_lbl(path & tr_lbl), te_img : mnist_img(path & te_img), te_lbl : mnist_lbl(path & te_lbl))
  
proc training_images*(m: var MNIST) : vvec =
  for i in 0..<m.tr_img.nItems:  result.add(m.tr_img.to_input_seq(i))

proc training_labels*(m: var MNIST) : vvec =
  for i in 0..<m.tr_lbl.nItems:  result.add(m.tr_lbl.get_label_seq(i))

proc test_images*(m: var MNIST) : vvec =
  for i in 0..<m.te_img.nItems:  result.add(m.te_img.to_input_seq(i))

proc test_labels*(m: var MNIST) : vvec =
  for i in 0..<m.te_lbl.nItems:  result.add(m.te_lbl.get_label_seq(i))

proc training_data*(m : var MNIST) : Training = [m.training_images(), m.training_labels()]
proc test_data*(m : var MNIST) : Training = [m.test_images(), m.test_labels()]

proc shuffle_training*(train : var Training) =
  let tr_len = train[0].len
  var 
    shseq=toSeq(0..<tr_len)
    sseq = shseq
  shseq.shuffle

  for (f,t) in zip(sseq, shseq):
    swap(train[0][f], train[0][f])
    swap(train[1][f], train[1][f])