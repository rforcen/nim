# Color Map

type vec3 = array[3, cfloat]

# generate a 0..1f rgb color vp in vmin..vmax, cm 0..25 color map kind

proc color_map*(vp, vmin, vmax: cfloat, cm: int): vec3 =
    let zv = [0f,0,0]

    result = [1f, 1, 1]

    var
        vmid = 0f
        ratio = 0f
        dv = 0f
        c1 = zv
        c2 = zv
        c3 = zv
        vmin = vmin
        vmax = vmax
        v = vp

    if vmax < vmin:
        dv = vmin
        vmin = vmax
        vmax = dv

    if vmax - vmin < 0.000001:
        vmin -= 1
        vmax += 1

    if v < vmin: v = vmin
    if v > vmax: v = vmax
    dv = vmax - vmin

    case cm:
        of 0..1:
            if v < (vmin + 0.25 * dv):
                result = [0f, 4f * (v - vmin) / dv, 1f]
            elif v < (vmin + 0.5 * dv):
                result = [0f, 1f, 1f + 4f * (vmin + 0.25 * dv - v) / dv]
            elif v < (vmin + 0.75 * dv):
                result[0] = 4f * (v - vmin - 0.5 * dv) / dv
                result[1] = 1f
                result[2] = 0f
            else:
                result[0] = 1f
                result[1] = 1f + 4f * (vmin + 0.75 * dv - v) / dv
                result[2] = 0f
        of 2:
            result[0] = (v - vmin) / dv
            result[1] = 0f
            result[2] = (vmax - v) / dv
        of 3:
            result[0] = (v - vmin) / dv
            result[2] = result[0]
            result[1] = result[0]

        of 4:
            if v < (vmin + dv / 6f):
                result[0] = 1
                result[1] = 6 * (v - vmin) / dv
                result[2] = 0
            elif v < (vmin + 2f * dv / 6f):
                result[0] = 1 + 6 * (vmin + dv / 6f - v) / dv
                result[1] = 1
                result[2] = 0
            elif v < (vmin + 3f * dv / 6f):
                result[0] = 0
                result[1] = 1
                result[2] = 6 * (v - vmin - 2f * dv / 6f) / dv
            elif v < (vmin + 4f * dv / 6f):
                result[0] = 0
                result[1] = 1 + 6 * (vmin + 3f * dv / 6f - v) / dv
                result[2] = 1
            elif v < (vmin + 5f * dv / 6f):
                result[0] = 6 * (v - vmin - 4f * dv / 6f) / dv
                result[1] = 0
                result[2] = 1
            else:
                result[0] = 1
                result[1] = 0
                result[2] = 1 + 6 * (vmin + 5f * dv / 6f - v) / dv
        of 5:
            result[0] = (v - vmin) / (vmax - vmin)
            result[1] = 1
            result[2] = 0
        of 6:
            result[0] = (v - vmin) / (vmax - vmin)
            result[1] = (vmax - v) / (vmax - vmin)
            result[2] = result[0]
        of 7:
            if v < (vmin + 0.25 * dv):
                result[0] = 0
                result[1] = 4 * (v - vmin) / dv
                result[2] = 1 - result[1]
            elif v < (vmin + 0.5 * dv):
                result[0] = 4 * (v - vmin - 0.25 * dv) / dv
                result[1] = 1 - result[0]
                result[2] = 0
            elif v < (vmin + 0.75 * dv):
                result[1] = 4 * (v - vmin - 0.5 * dv) / dv
                result[0] = 1 - result[1]
                result[2] = 0
            else:
                result[0] = 0
                result[2] = 4 * (v - vmin - 0.75 * dv) / dv
                result[1] = 1 - result[2]
        of 8:
            if v < (vmin + 0.5 * dv):
                result[0] = 2 * (v - vmin) / dv
                result[1] = result[0]
                result[2] = result[0]
            else:
                result[0] = 1 - 2 * (v - vmin - 0.5 * dv) / dv
                result[1] = result[0]
                result[2] = result[0]
        of 9:
            if v < (vmin + dv / 3):
                result[2] = 3 * (v - vmin) / dv
                result[1] = 0
                result[0] = 1 - result[2]
            elif v < (vmin + 2 * dv / 3):
                result[0] = 0
                result[1] = 3 * (v - vmin - dv / 3) / dv
                result[2] = 1
            else:
                result[0] = 3 * (v - vmin - 2 * dv / 3) / dv
                result[1] = 1 - result[0]
                result[2] = 1
        of 10:
            if v < (vmin + 0.2 * dv):
                result[0] = 0
                result[1] = 5 * (v - vmin) / dv
                result[2] = 1
            elif v < (vmin + 0.4 * dv):
                result[0] = 0
                result[1] = 1
                result[2] = 1 + 5 * (vmin + 0.2 * dv - v) / dv
            elif v < (vmin + 0.6 * dv):
                result[0] = 5 * (v - vmin - 0.4 * dv) / dv
                result[1] = 1
                result[2] = 0
            elif v < (vmin + 0.8 * dv):
                result[0] = 1
                result[1] = 1 - 5 * (v - vmin - 0.6 * dv) / dv
                result[2] = 0
            else:
                result[0] = 1
                result[1] = 5 * (v - vmin - 0.8 * dv) / dv
                result[2] = 5 * (v - vmin - 0.8 * dv) / dv
        of 11:
            c1[0] = 200f / 255f
            c1[1] = 60f / 255f
            c1[2] = 0.0f / 255f
            c2[0] = 250f / 255f
            c2[1] = 160f / 255f
            c2[2] = 110f / 255f
            result[0] = (c2[0] - c1[0]) * (v - vmin) / dv + c1[0]
            result[1] = (c2[1] - c1[1]) * (v - vmin) / dv + c1[1]
            result[2] = (c2[2] - c1[2]) * (v - vmin) / dv + c1[2]
        of 12:
            c1[0] = 55f / 255f
            c1[1] = 55 / 255f
            c1[2] = 45 / 255f
            ##  c2[0] = 200 / 255f; c2[1] =  60 / 255f; c2[2] =   0 / 255f;
            c2[0] = 235 / 255f
            c2[1] = 90 / 255f
            c2[2] = 30 / 255f
            c3[0] = 250 / 255f
            c3[1] = 160 / 255f
            c3[2] = 110 / 255f
            ratio = 0.4
            vmid = vmin + ratio * dv
            if v < vmid:
                result[0] = (c2[0] - c1[0]) * (v - vmin) / (ratio * dv) + c1[0]
                result[1] = (c2[1] - c1[1]) * (v - vmin) / (ratio * dv) + c1[1]
                result[2] = (c2[2] - c1[2]) * (v - vmin) / (ratio * dv) + c1[2]
            else:
                result[0] = (c3[0] - c2[0]) * (v - vmid) / ((1 - ratio) * dv) + c2[0]
                result[1] = (c3[1] - c2[1]) * (v - vmid) / ((1 - ratio) * dv) + c2[1]
                result[2] = (c3[2] - c2[2]) * (v - vmid) / ((1 - ratio) * dv) + c2[2]
        of 13:
            c1[0] = 0 / 255f
            c1[1] = 255 / 255f
            c1[2] = 0 / 255f
            c2[0] = 255 / 255f
            c2[1] = 150 / 255f
            c2[2] = 0 / 255f
            c3[0] = 255 / 255f
            c3[1] = 250 / 255f
            c3[2] = 240 / 255f
            ratio = 0.3
            vmid = vmin + ratio * dv
            if v < vmid:
                result[0] = (c2[0] - c1[0]) * (v - vmin) / (ratio * dv) + c1[0]
                result[1] = (c2[1] - c1[1]) * (v - vmin) / (ratio * dv) + c1[1]
                result[2] = (c2[2] - c1[2]) * (v - vmin) / (ratio * dv) + c1[2]
            else:
                result[0] = (c3[0] - c2[0]) * (v - vmid) / ((1 - ratio) * dv) + c2[0]
                result[1] = (c3[1] - c2[1]) * (v - vmid) / ((1 - ratio) * dv) + c2[1]
                result[2] = (c3[2] - c2[2]) * (v - vmid) / ((1 - ratio) * dv) + c2[2]
        of 14:
            result[0] = 1
            result[1] = 1 - (v - vmin) / dv
            result[2] = 0
        of 15:
            if v < (vmin + 0.25 * dv):
                result[0] = 0
                result[1] = 4 * (v - vmin) / dv
                result[2] = 1
            elif v < (vmin + 0.5 * dv):
                result[0] = 0
                result[1] = 1
                result[2] = 1 - 4 * (v - vmin - 0.25 * dv) / dv
            elif v < (vmin + 0.75 * dv):
                result[0] = 4 * (v - vmin - 0.5 * dv) / dv
                result[1] = 1
                result[2] = 0
            else:
                result[0] = 1
                result[1] = 1
                result[2] = 4 * (v - vmin - 0.75 * dv) / dv
        of 16:
            if v < (vmin + 0.5 * dv):
                result[0] = 0f
                result[1] = 2 * (v - vmin) / dv
                result[2] = 1 - 2 * (v - vmin) / dv
            else:
                result[0] = 2 * (v - vmin - 0.5 * dv) / dv
                result[1] = 1 - 2 * (v - vmin - 0.5 * dv) / dv
                result[2] = 0f
        of 17:
            if v < (vmin + 0.5 * dv):
                result[0] = 1f
                result[1] = 1 - 2 * (v - vmin) / dv
                result[2] = 2 * (v - vmin) / dv
            else:
                result[0] = 1 - 2 * (v - vmin - 0.5 * dv) / dv
                result[1] = 2 * (v - vmin - 0.5 * dv) / dv
                result[2] = 1f
        of 18:
            result[0] = 0
            result[1] = (v - vmin) / (vmax - vmin)
            result[2] = 1
        of 19:
            result[0] = (v - vmin) / (vmax - vmin)
            result[1] = result[0]
            result[2] = 1
        of 20:
            c1[0] = 0 / 255f
            c1[1] = 160 / 255f
            c1[2] = 0 / 255f
            c2[0] = 180 / 255f
            c2[1] = 220 / 255f
            c2[2] = 0 / 255f
            c3[0] = 250 / 255f
            c3[1] = 220 / 255f
            c3[2] = 170 / 255f
            ratio = 0.3
            vmid = vmin + ratio * dv
            if v < vmid:
                result[0] = (c2[0] - c1[0]) * (v - vmin) / (ratio * dv) + c1[0]
                result[1] = (c2[1] - c1[1]) * (v - vmin) / (ratio * dv) + c1[1]
                result[2] = (c2[2] - c1[2]) * (v - vmin) / (ratio * dv) + c1[2]
            else:
                result[0] = (c3[0] - c2[0]) * (v - vmid) / ((1 - ratio) * dv) + c2[0]
                result[1] = (c3[1] - c2[1]) * (v - vmid) / ((1 - ratio) * dv) + c2[1]
                result[2] = (c3[2] - c2[2]) * (v - vmid) / ((1 - ratio) * dv) + c2[2]
        of 21:
            c1[0] = 255 / 255f
            c1[1] = 255 / 255f
            c1[2] = 200 / 255f
            c2[0] = 150 / 255f
            c2[1] = 150 / 255f
            c2[2] = 255 / 255f
            result[0] = (c2[0] - c1[0]) * (v - vmin) / dv + c1[0]
            result[1] = (c2[1] - c1[1]) * (v - vmin) / dv + c1[1]
            result[2] = (c2[2] - c1[2]) * (v - vmin) / dv + c1[2]
        of 22:
            result[0] = 1 - (v - vmin) / dv
            result[1] = 1 - (v - vmin) / dv
            result[2] = (v - vmin) / dv
        of 23:
            if v < (vmin + 0.5 * dv):
                result[0] = 1
                result[1] = 2 * (v - vmin) / dv
                result[2] = result[1]
            else:
                result[0] = 1 - 2 * (v - vmin - 0.5 * dv) / dv
                result[1] = result[0]
                result[2] = 1
        of 24:
            if v < (vmin + 0.5 * dv):
                result[0] = 2 * (v - vmin) / dv
                result[1] = result[0]
                result[2] = 1 - result[0]
            else:
                result[0] = 1
                result[1] = 1 - 2 * (v - vmin - 0.5 * dv) / dv
                result[2] = 0
        of 25:
            if v < (vmin + dv / 3):
                result[0] = 0
                result[1] = 3 * (v - vmin) / dv
                result[2] = 1
            elif v < (vmin + 2 * dv / 3):
                result[0] = 3 * (v - vmin - dv / 3) / dv
                result[1] = 1 - result[0]
                result[2] = 1
            else:
                result[0] = 1
                result[1] = 0
                result[2] = 1 - 3 * (v - vmin - 2 * dv / 3) / dv
        else:
            result = zv
