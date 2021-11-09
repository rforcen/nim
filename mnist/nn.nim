# nn.nim perceptron mnist 
# nim c -r -d:release -d:danger nn

import mnist, mat, random, sequtils, times, math, streams

## NN

type 
  NN* = object
    nlayers* : int
    w*: vmat
    b*: vvec
    deltaW* : vmat
    deltaB* : vvec

proc newNN*(sizes:openarray[int]) : NN =
  result.nlayers = sizes.len

  randomize()
  for y in sizes[1..^1]: result.b.add(rand_vec(y))
  for (x,y) in zip(sizes[0..^1], sizes[1..^1]): result.w.add(rand_mat(y,x))

  result.deltaW = result.w.from_shape # deltas=0
  result.deltaB = result.b.from_shape

proc evaluate*(nn:NN, input:vec):vec=
  result = input

  for (w,b) in zip(nn.w, nn.b):
    result = w.wab(result, b).sigmoid

# digit 0..9 closer to input image
func eval_digit*(nn:NN, input:vec):int =  nn.evaluate(input).maxIndex

proc test_factor*(nn:NN, test_data:Training):real=
  for (image, label) in zip(test_data.images, test_data.labels):
    if nn.eval_digit(image) == label.find(1.0): 
      result += 1

  result / test_data.images.len.real

proc cost_derivative(a,b:vec):vec = a - b

proc backpropagation( nn : NN, input_data, test_data : vec) : (vmat, vvec) =
  var
    activation = input_data
    activations, zs : mat
  
  # feed-fwd
  activations.add(input_data)

  for (w,b) in zip(nn.w, nn.b):
    var z = w.wab(activation,b) # w*activation+b

    zs.add(z)
    activation = z.sigmoid
    activations.add(activation)

  # backward pass
  var 
    deltaW = nn.w.from_shape
    deltaB = nn.b.from_shape
    delta : vec = cost_derivative(activations[^1], test_data) * (zs[^1].sigmoid_prime)

  deltaB[^1] = delta
  deltaW[^1] = delta .** activations[^2]

  for l in 2..<nn.nlayers: 
    var sp = zs[^l].sigmoid_prime
    delta = (nn.w[^(l-1)].transpose .* delta) * sp

    deltaB[^l] = delta
    deltaW[^l] = delta .** activations[^(l+1)]

  (deltaW, deltaB)

# 1 epoch learning
proc learn*(nn:var NN, training_data: Training, eta : real) =
  for (input, output) in zip(training_data.images, training_data.labels):

      let (deltaW, deltaB) = nn.backpropagation(input, output)

      nn.w -= deltaW * eta
      nn.b -= deltaB * eta

proc SGD(nn : var NN, training_data, test_data : var Training, nepochs : int = 10, eta : real = 0.3) : real =

  for epoch in 0..<nepochs:
    let t0 = now()
    write stdout, "epoch ", epoch, ": "; stdout.flushFile
    
    training_data.shuffle_training 

    nn.learn(training_data, eta)
    
    echo " learn factor:", (100.0 * nn.test_factor(test_data)).floor, "%, lap:",(now()-t0).inSeconds,"\""

  (nn.test_factor(test_data) * 100).floor

proc save*(nn:NN, file_name : string)= # nim source can be used as training starting point
  var s = newFileStream(file_name, fmWrite)
  write s, "let weight_learnt* =", nn.w, "\n"
  write s, "let biass_learnt* =", nn.b, "\n"
  s.close

##################
when isMainModule:

  proc test_nn* =
    var mnist = newMNIST()

    echo "loading training data..."

    var 
      training_data = mnist.training_data()
      test_data = mnist.test_data()


    if test_data.images.len==0: 
      raise Exception.newException("empty test data, end") 

    let # nn topology
      img_sz = training_data.images[0].len
      n_mid_layers = 30
      n_digits = 10

    var nn = newNN [img_sz, n_mid_layers, n_digits]

    echo "mnist training..."
    echo "done, learn factor:", nn.SGD(training_data, test_data, nepochs=6, eta=0.3), "%"
    echo "saving to mnist_learnt.nim"
    nn.save("mnist_learnt.nim")

  test_nn()
