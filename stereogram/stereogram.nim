# color & textured stereograms

import random, sequtils, pixie

# misc funcs
{.push inline.}
proc mindepth(separationFactor:float, maxdepth, observationDistance, suppliedMinDepth : int) : int =
  let computedMinDepth = ( (separationFactor * maxdepth.float * observationDistance.float) /
    (((1 - separationFactor) * maxdepth.float) + observationDistance.float) ).int
  min(max(computedMinDepth, suppliedMinDepth), maxdepth)

proc maxdepth(suppliedMaxDepth, observationDistance :  int) : int =  max( min( suppliedMaxDepth, observationDistance), 0)

proc topixels(valueInches : float, ppi : int) : int =  (valueInches * ppi.float).int
    
proc getRed(color:ColorRGBX) : int = color.r.int

proc depth(depth : ColorRGBX, maxDepth, minDepth :  int) : int =  maxDepth - (getRed(depth) * (maxDepth - minDepth) div 255)
    
proc separation(observationDistance, eyeSeparation, depth : int) : int = (eyeSeparation * depth) div (depth + observationDistance)
{.pop.}

# stereogram color generator
proc generateSIRD*(depthMap : Image, color1, color2, color3 : ColorRGBX, colorIntensity : float,
  width, height : int,  observationDistanceInches = 14.0, eyeSeparationInches = 2.5,
  maxDepthInches = 12.0, minDepthInches : float = 0,  horizontalPPI : int = 72) : Image =

    var stereogram = newImage(width, height)

    let 
      rdepthMap   = depthMap.resize(width, height)

      seq0_w = toSeq(0..<width)

      observationDistance = topixels(observationDistanceInches, horizontalPPI)
      eyeSeparation       = topixels(eyeSeparationInches, horizontalPPI)
      maxdepth            = maxdepth( topixels(maxDepthInches, horizontalPPI), observationDistance )
      minDepth            = mindepth(0.55, maxdepth, observationDistance, topixels(minDepthInches, horizontalPPI) )
      colors  = [color1, color2, color3]

    proc choose_color : ColorRGBX =
      if color3==rgbx(0,0,0,0): 
        if rand(1.0) < colorIntensity: colors[0]
        else: colors[1]
      else: colors.sample

    for l in 0..<height:
      var
        linksL = seq0_w
        linksR = seq0_w

      for c in 0..<width:
        let
          depth = depth( rdepthMap[c, l], maxdepth, minDepth )
          separation = separation( observationDistance, eyeSeparation, depth )
          left = c - (separation div 2)
          right = left + separation

        if left >= 0 and right < width:
          var visible = true

          if linksL[right] != right:
            if linksL[right] < left:
              linksR[linksL[right]] = linksL[right]
              linksL[right] = right
            else:   visible = false 
          
          if linksR[left] != left:
            if linksR[left] > right:
              linksL[linksR[left]] = linksR[left]
              linksR[left] = left
            else: visible = false 
          
          if visible: linksL[right] = left; linksR[left] = right      

      for c in 0..<width:
        stereogram[c, l] =
          if linksL[c] == c:  choose_color()
          else: stereogram[linksL[c], l]
    
    stereogram
    
# textured stereogram generator
proc generateTexturedSIRD(depthMap, texturePattern : Image,
  width, height : int,
  observationDistanceInches, eyeSeparationInches,  maxDepthInches, minDepthInches : float,
  horizontalPPI, verticalPPI : int ) : Image =

  var stereogram = newImage(width, height)

  let 
    rdepthMap = depthMap.resize(width, height)
    seq0_w = toSeq(0..<width)

    observationDistance = topixels(observationDistanceInches, horizontalPPI)
    eyeSeparation = topixels(eyeSeparationInches, horizontalPPI)
    maxDepth = maxdepth( topixels(maxDepthInches, horizontalPPI), observationDistance )
    minDepth = mindepth( 0.55, maxDepth, observationDistance, topixels(minDepthInches, horizontalPPI) )
    verticalShift = verticalPPI div 16
    maxSeparation = separation(observationDistance, eyeSeparation, maxDepth)
    wtexturePattern = texturePattern.resize(maxSeparation , maxSeparation)

  for l in 0..<height:
    var
      linksL = seq0_w
      linksR = seq0_w
    
    for c in 0..<width:
      let
        depth = depth( rdepthMap[c,l], maxDepth, minDepth )
        separation = separation(observationDistance, eyeSeparation, depth)
        left = c - (separation div 2)
        right = left + separation

      if left >= 0 and right < width:
        var visible = true

        if linksL[right] != right:
          if linksL[right] < left:
            linksR[linksL[right]] = linksL[right]
            linksL[right] = right
          else:  visible = false 
          
        if linksR[left] != left:
          if linksR[left] > right:
            linksL[linksR[left]] = linksR[left]
            linksR[left] = left
          else: visible = false

        if visible:
          linksL[right] = left
          linksR[left] = right
                    
    var lastLinked = -10
    for c in 0..<width:
      if linksL[c] == c:
        stereogram[c, l] =  
          if lastLinked == c - 1: stereogram[c - 1, l]
          else: wtexturePattern[c %% maxSeparation, (l + ((c div maxSeparation) * verticalShift)) %% wtexturePattern.height]
      else:
        stereogram[c, l] = stereogram[linksL[c], l]
        lastLinked = c
  
  stereogram
    

# color defs
const
  red = rgbx(255,0,0,255)
  green = rgbx(0,255,0,255)
  blue = rgbx(0,0,255,255)
  black = rgbx(0,0,0,255)
  white = rgbx(255,255,255,255)

##
when isMainModule:
  let 
    path ="stereogram/"
    width=1024
    height=768

    depthMap = readImage(path & "images/depthMaps/3gear.jpg")
    texture = readImage(path & "images/texturePatterns/txt4.png")

    stereogramc = generateSIRD(
      depthMap, black, white, red, colorIntensity=0.5,  width, height, 
      observationDistanceInches= 14, eyeSeparationInches=2.5, maxDepthInches=12, minDepthInches=0, horizontalPPI=72)
    
    stereogramt = generateTexturedSIRD(depthMap, texture, width, height, 
      observationDistanceInches= 14, eyeSeparationInches=2.5, maxDepthInches=12, minDepthInches=0, horizontalPPI=72, verticalPPI=72)

  stereogramc.writeFile path & "stereogram_color.png"
  stereogramt.writeFile path & "stereogram_texture.png"