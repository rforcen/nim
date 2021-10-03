# Symmetric Icons
import pixie

# lambda, alpha, beta, gamma, omega, symmetry, scale
const PRESETS: array[36, array[7, float64]] = [
    [1.56, -1.0, 0.1, -0.82, -0.3, 3.0, 1.7],
    [-1.806, 1.806, 0.0, 1.5, 0.0, 7.0, 1.1],
    [2.4, -2.5, -0.9, 0.9, 0.0, 3.0, 1.5],
    [-2.7, 5.0, 1.5, 1.0, 0.0, 4.0, 1.0],
    [-2.5, 8.0, -0.7, 1.0, 0.0, 5.0, 0.8],
    [-1.9, 1.806, -0.85, 1.8, 0.0, 7.0, 1.2],
    [2.409, -2.5, 0.0, 0.9, 0.0, 4.0, 1.4],
    [-1.806, 1.807, -0.07, 1.08, 0.0, 6.0, 1.2],
    [-2.34, 2.2, 0.4, 0.05, 0.0, 5.0, 1.2],
    [-2.57, 3.2, 1.2, -1.75, 0.0, 36.0, 1.2],
    [-2.6, 4.0, 1.5, 1.0, 0.0, 12.0, 1.1],
    [-2.2, 2.3, 0.55, -0.90, 0.0, 3.0, 1.3],
    [-2.205, 6.01, 13.5814, -0.2044, 0.011, 5.0, 0.8],
    [-2.7, 8.7, 13.86, -0.13, -0.18, 18.0, 0.8],
    [-2.52, 8.75, 12.0, 0.04, 0.18, 5.0, 0.8],
    [2.38, -4.18, 19.99, -0.69, 0.095, 17.0, 1.0],
    [2.33, -8.22, -6.07, -0.52, 0.16, 4.0, 0.8],
    [-1.62, 2.049, 1.422, 1.96, 0.56, 6.0, 1.0],
    [-1.89, 9.62, 1.95, 0.51, 0.21, 3.0, 0.6],
    [-1.65, 9.99, 1.57, 1.46, -0.55, 3.0, 0.8],
    [-2.7, 5.0, 1.5, 1.0, 0.0, 6.0, 1.0],
    [-2.08, 1.0, -0.1, 0.167, 0.0, 7.0, 1.3],
    [1.56, -1.0, 0.1, -0.82, 0.12, 3.0, 1.6],
    [-1.806, 1.806, 0.0, 1.0, 0.0, 5.0, 1.1],
    [1.56, -1.0, 0.1, -0.82, 0.0, 3.0, 1.3],
    [-2.195, 10.0, -12.0, 1.0, 0.0, 3.0, 0.7],
    [-1.86, 2.0, 0.0, 1.0, 0.1, 4.0, 1.2],
    [-2.34, 2.0, 0.2, 0.1, 0.0, 5.0, 1.2],
    [2.6, -2.0, 0.0, 0.5, 0.0, 5.0, 1.3],
    [-2.5, 5.0, -1.9, 1.0, 0.188, 5.0, 1.0],
    [2.409, -2.5, 0.0, 0.9, 0.0, 23.0, 1.2],
    [2.409, -2.5, -0.2, 0.81, 0.0, 24.0, 1.2],
    [-2.05, 3.0, -16.79, 1.0, 0.0, 9.0, 1.0],
    [-2.32, 2.32, 0.0, 0.75, 0.0, 5.0, 1.2],
    [2.5, -2.5, 0.0, 0.9, 0.0, 3.0, 1.3],
    [1.5, -1.0, 0.1, -0.805, 0.0, 3.0, 1.4],
]

const
    MAX_XY: float32 = 1e5
    DEFAULT_SPEED: uint32 = 100
    MAX_COLORS: uint32 = 2111
    COLOR_SPEED: uint32 = 3071




type SymmetricIcons = object
    lambda, alpha, beta, gamma, omega: float32
    symmetry: uint32
    scale: float32

    len: int
    color_set: uint32
    iter: uint32
    speed: uint32

    apcx, apcy: float32
    rad: float32

    color_list: seq[uint32]
    icon: seq[uint32]
    image: seq[uint32]

    x, y: float32

    k: uint32


# fwd decl
proc set_preset*(si: var SymmetricIcons, i: int)
proc reset_icon(si: var SymmetricIcons)
proc at(si: SymmetricIcons, x, y: int): int {.inline.} = x * si.len + y

# proc new2d(l: int): seq[seq[uint32]] = newSeqWith(l, newSeq[uint32](l))

proc newSymmetricIcon*(len: int, preset: int,
        color_set: uint32): SymmetricIcons =
    var s = SymmetricIcons(
        lambda: 0.0,
        alpha: 0.0,
        beta: 0.0,
        gamma: 0.0,
        omega: 0.0,
        symmetry: 0,
        scale: 0.0,

        len: len,

        color_set: color_set,
        iter: 0,

        speed: DEFAULT_SPEED,
        apcx: 0.0,
        apcy: 0.0,
        rad: 0.0,

        # color_list: newSeq[uint32](),
            # icon: new2d(len),
            # image: new2d(len),

        x: 0.0,
        y: 0.0,
        k: 0)

    s.set_preset(preset)
    s

proc set_size*(si: var SymmetricIcons, len: int) =
    si.len = len

    si.image = newSeq[uint32](len*len)
    si.icon = newSeq[uint32](len*len)
    si.iter = 0

    # si.color_list = newSeq[uint32]()

    si.reset_icon()


proc set_preset*(si: var SymmetricIcons, i: int) =
    let p = PRESETS[i %% PRESETS.len]

    si.lambda = p[0]
    si.alpha = p[1]
    si.beta = p[2]
    si.gamma = p[3]
    si.omega = p[4]
    si.symmetry = p[5].uint32
    si.scale = if p[6] == 0.0: 1.0 else: p[6]

    si.reset_icon()


proc set_parameters*(
    si: var SymmetricIcons,
    lambda: float32,
    alpha: float32,
    beta: float32,
    gamma: float32,
    omega: float32,
    symmetry: float32,
    scale: float32,
) =
    si.lambda = lambda
    si.alpha = alpha
    si.beta = beta
    si.gamma = gamma
    si.omega = omega

    si.symmetry = if symmetry < 1.0: 1.uint32 else: symmetry.uint32
    si.scale = if scale == 0.0: 1.0 else: scale

    si.reset_icon()


proc set_colors(si: var SymmetricIcons, param_int: uint32) =
    proc make_color(r: uint32, g: uint32, b: uint32): uint32 =
        (b.shl 16) or (g.shl 8) or r or 0xff00_0000'u32

    proc make_colora(a: uint32, r: uint32, g: uint32, b: uint32): uint32 =
        (a.shl 24) or (b.shl 16) or (g.shl 8) or r

    proc get_rainbow(x: uint32, y: uint32): uint32 =
        case x:
            of 0: make_color(0, y, 255)
            of 1: make_color(0, 255, 255 - y)
            of 2: make_color(y, 255, 0)
            of 3: make_color(255, 255 - y, 0)
            of 4: make_color(255, 0, y)
            of 5: make_color(255 - y, 0, 255)
            else: make_color(0, 0, 0) # black

    var colors = newSeq[uint32](MAX_COLORS + 1)

    case param_int:
        of 0:
            for i in 0..<64:
                colors[i] = make_color(0, 0, 4 * i.uint32)

            for i in 0..<256:
                let local_color = make_color(255, i.uint32, 255)
                for j in 0..<3:
                    colors[1344 + j + 3 * i] = local_color
        of 1:
            for i in 0..<64:
                colors[i] = make_color(0, 4 * i.uint32, 4 * i.uint32)

            for i in 0..<256:
                let local_color = make_color(i.uint32, i.uint32, 255)
                for j in 0..<3:
                    colors[1344 + j + 3 * i] = local_color
        of 2:
            for i in 0..<64:
                colors[i] = make_color(0, 4 * i.uint32, 0)

            for i in 0..<256:
                let local_color = make_color(i.uint32, 255, 255)
                for j in 0..<3:
                    colors[1344 + j + 3 * i] = local_color
        of 3:
            for i in 0..<64:
                colors[i] = make_color(4 * i.uint32, 4 * i.uint32, 0)

            for i in 0..<256:
                let local_color = make_color(i.uint32, 255, i.uint32)
                for j in 0..<3:
                    colors[1344 + j + 3 * i] = local_color
        of 4:
            for i in 0..<64:
                colors[i] = make_color(4 * i.uint32, 0, 0)

            for i in 0..<256:
                let local_color = make_color(255, 255, i.uint32)
                for j in 0..<3:
                    colors[1344 + j + 3 * i] = local_color
        of 5:
            for i in 0..<64:
                colors[i] = make_color(4 * i.uint32, 0, 4 * i.uint32)

            for i in 0..<256:
                let local_color = make_color(255, i.uint32, i.uint32)
                for j in 0..<3:
                    colors[1344 + j + 3 * i] = local_color
        of 6:
            for i in 0..<256:
                colors[i + 64] = make_colora(255, 255 - i.uint32, 255 -
                        i.uint32, 255)
        of 7:
            for i in 0..<256:
                colors[i + 64] = make_color(255 - i.uint32, 255, 255)
        of 8:
            for i in 0..<256:
                colors[i + 64] = make_color(255 - i.uint32, 255, 255 - i.uint32)
        of 9:
            for i in 0..<256:
                colors[i + 64] = make_color(255, 255, 255 - i.uint32)
        of 10:
            for i in 0..<256:
                colors[i + 64] = make_color(255, 255 - i.uint32, 255 - i.uint32)
        of 11:
            for i in 0..<256:
                colors[i + 64] = make_color(255, 255 - i.uint32, 255)

        else: discard

    if param_int > 5:
        for i in 0..<64:
            colors[i] = make_color(4 * i.uint32, 4 * i.uint32, 4 * i.uint32)

        for j in 0..<5:
            for i in 0..<256:
                colors[320 + j * 256 + i] = get_rainbow(((param_int.int + j) %%
                        6).uint32, i.uint32)


        for i in 0..<256:
            let local_color = get_rainbow(((param_int - 1).int %% 6).uint32, i.uint32)
            colors[(1600 + 2 * i.int)] = local_color
            colors[(1601 + 2 * i.int)] = local_color

    else:
        # <= 5
        for j in 0..<5:
            for i in 0..<256:
                colors[64 + j * 256 + i] = get_rainbow(((param_int.int + j) %%
                        6).uint32, i.uint32)

    si.color_list = colors


proc get_color(si: var SymmetricIcons, col: uint32): uint32 {.inline.} =
    let col = col and 0x00ffffff
    if col * si.speed > MAX_COLORS:
        while (col * si.speed > COLOR_SPEED) and (si.speed > 3):
            si.speed.dec

        si.color_list[MAX_COLORS]
    else:
        si.color_list[col * si.speed]

proc get_icon(si: SymmetricIcons, x, y: int): uint32{.inline.} = si.icon[x*si.len+y]
proc set_pixel(si: var SymmetricIcons, x, y: int, color: uint32) {.
        inline.} = si.image[x*si.len+y] = color

proc set_point(si: var SymmetricIcons, x: int, y: int) {.inline.} =
    if x < si.len and y < si.len:
        let
            icon = si.get_icon(x, y)
            color = si.get_color(icon)

        si.set_pixel(x, y, color)
        si.icon[si.at(x, y)].inc
        if icon >= 12288: si.icon[si.at(x, y)] = 8192

proc reset_icon(si: var SymmetricIcons) =
    si.speed = DEFAULT_SPEED

    si.apcx = si.len.float32 / 2.0
    si.apcy = si.len.float32 / 2.0
    si.rad = if si.apcx > si.apcy: si.apcy else: si.apcx

    si.k = 0
    si.x = 0.01
    si.y = 0.003
    si.iter = 0

    si.icon = newSeq[uint32](si.len * si.len)
    si.image = newSeq[uint32](si.len * si.len)
    si.set_colors(si.color_set)

    for m in 0..<si.len:
        for n in 0..<si.len:
            let color = si.get_color(si.get_icon(m, n))
            si.set_pixel(m, n, color)


proc gen1*(si: var SymmetricIcons) = # generate icon, 1 iter
    si.iter.inc

    if si.x.abs() > MAX_XY or si.y.abs() > MAX_XY:
        si.reset_icon() # prevent overflow
    

    # generate new x,y
    let sq = si.x * si.x + si.y * si.y # sq=x^2+y^2

    var
        tx = si.x
        ty = si.y # tx=pow, ty=pow

    for m in 1..<si.symmetry - 2 + 1:
        let
            sqx = tx * si.x - ty * si.y
            sqy = ty * si.x + tx * si.y

        tx = sqx
        ty = sqy


    let
        sqx = si.x * tx - si.y * ty
        tmp = si.lambda + si.alpha * sq + si.beta * sqx
        x_new = tmp * si.x + si.gamma * tx - si.omega * si.y
        y_new = tmp * si.y - si.gamma * ty + si.omega * si.x

    si.x = x_new
    si.y = y_new

    if si.k > 50:
        si.set_point(
            (si.apcx + si.x * si.rad / si.scale).int,
            (si.apcy + si.y * si.rad / si.scale).int,
        )
    else:
        si.k.inc

proc generate*(si: var SymmetricIcons, n_iters: int) =
    for i in 0..<n_iters:
        si.gen1()

proc write_image*(si: SymmetricIcons, fn: string) =
    let image = newImage(si.len, si.len)
    image.data = cast[seq[ColorRGBX]](si.image)
    image.writeFile(fn)

when isMainModule:
    import times
    let
        w = 1024*2
        iters = 20_000_000
        preset = 8
        color_set = 0'u32

    echo "generating symmetric icon, w x w=", w*w, ", preset:", preset, ", iters=", iters, "..."

    let start = now()
    var si = newSymmetricIcon(w, preset, color_set)
    si.generate(iters)

    echo "done in: ", (now()-start).inMilliseconds, "ms, generated file symm_icn.png"
    si.write_image("symm_icn.png")
