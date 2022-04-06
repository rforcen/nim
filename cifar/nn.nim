# nn.nim perceptron cifar 
# nim c -r -d:release -d:danger nn

import cifar, mat, random, sequtils, times, math, streams

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

proc test_factor*(nn:NN, cifar:Cifar):real=
  for i in 0..<cifar.ntest:
    let test = cifar.test[i]
    if nn.eval_digit(test.image) == test.label: 
      result += 1

  result / n_recs

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
proc learn*(nn:var NN, cifar: Cifar, eta : real) =
  for i in 0..<cifar.ntrain:
      let
        input = cifar.training[i].image
        output = cifar.training[i].label

        (deltaW, deltaB) = nn.backpropagation(input, output)

      nn.w -= deltaW * eta
      nn.b -= deltaB * eta

proc SGD(nn : var NN, cifar : Cifar, nepochs : int = 10, eta : real = 0.3) : real =

  for epoch in 0..<nepochs:
    let t0 = now()
    write stdout, "epoch ", epoch, ": "; stdout.flushFile
    
    # training_data.shuffle_training 

    nn.learn(cifar, eta)
    
    echo "error rate:", (100.0 * (1-nn.test_factor(cifar))).floor, "%, lap:",(now()-t0).inSeconds,"\""

  ((1-nn.test_factor(cifar)) * 100).floor

proc save*(nn:NN, file_name : string)= # nim source can be used as training starting point
  var s = newFileStream(file_name, fmWrite)
  write s, "let weight_learnt* =", nn.w, "\n"
  write s, "let biass_learnt* =", nn.b, "\n"
  s.close

##################
when isMainModule:

  proc test_nn* =
    echo "loading training data..."
    let cifar = load_cifar()

    let # nn topology
      img_sz = image_size
      n_mid_layers = 30
      n_digits = 10

    var nn = newNN [img_sz, 120, 84, n_digits]

    echo "cifar training..."
    echo "done, error rate:", nn.SGD(cifar, nepochs=30, eta=0.9), "%"
    # echo "saving to cifar_learnt.nim"
    # nn.save("cifar_learnt.nim")

  test_nn()
