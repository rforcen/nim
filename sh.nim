# Spherical Harmonics

# using parallel
# compile w/
# nim c --threads:on --experimental sh.nim
#

import math, glm, sugar, streams, weave, times, strformat

# preset codes
const SH_N_CODES = 647
const SPHERICAL_HARMONICS_CODES: array[SH_N_CODES, int] = [
    1222412, 1410121, 1420121, 1434301, 1441324, 1444401, 1444421, 2222222,
    2240322, 2420214,
    2441224, 4026442, 4032241, 4240412, 4310132, 4322142, 4323242, 4410112,
    4422122, 4422133,
    4422242, 11111212, 11112242, 11121314, 11121442, 11121443, 11132444,
    11134321, 11142241,
    11143234, 11214244, 11223344, 11224224, 11232334, 11242234, 11244141,
    11244224, 11244444,
    11311232, 11314442, 11321224, 11321242, 11331442, 11334422, 11344234,
    11413142, 11421122,
    11421133, 11421244, 11422233, 11434241, 11441111, 11442211, 12121224,
    12123222, 12123244,
    12124232, 12141212, 12221422, 12222212, 12222242, 12223242, 12244424,
    12320124, 12321244,
    12322141, 12341234, 12414244, 12420224, 12420244, 12421442, 12422232,
    12431424, 12442124,
    13121242, 13134224, 13142244, 13224424, 13243234, 13312222, 13313342,
    13324143, 13332424,
    13342114, 13422421, 13422421, 13434243, 13443212, 13443244, 13444124,
    14032211, 14122442,
    14126211, 14131214, 14142242, 14222231, 14222414, 14234211, 14234214,
    14241424, 14242414,
    14243444, 14322212, 14333242, 14344432, 14414232, 14422143, 14431243,
    14432424, 14434241,
    14444122, 14444232, 21022212, 21023122, 21030324, 21142223, 21142424,
    21210412, 21212121,
    21213434, 21214422, 21222222, 21222422, 21224212, 21234314, 21332321,
    21333444, 21344422,
    21412441, 21413214, 21413434, 21422122, 21422241, 21442221, 22023304,
    22024402, 22041224,
    22113231, 22124144, 22133212, 22141344, 22144344, 22212414, 22222244,
    22223232, 22224231,
    22224242, 22232442, 22243224, 22243442, 22314442, 22323222, 22323322,
    22334334, 22344234,
    22344404, 22411232, 22411432, 22420214, 22424222, 22424224, 22431442,
    22432424, 22442212,
    22442344, 22443232, 23112442, 23124422, 23124443, 23134234, 23142213,
    23142314, 23143212,
    23214221, 23224442, 23230324, 23232322, 23242441, 23244133, 23312441,
    23324424, 23332244,
    23344241, 23412342, 23414421, 23424144, 23432332, 23434423, 23442443,
    23444233, 23444312,
    24024442, 24112332, 24124442, 24133441, 24134314, 24144342, 24213423,
    24222224, 24222422,
    24222442, 24224422, 24234422, 24241212, 24242142, 24242412, 24243434,
    24244224, 24313124,
    24324433, 24330324, 24330324, 24333333, 24341423, 24412424, 24422214,
    24422222, 24423423,
    24431212, 24442231, 24444222, 31112444, 31124442, 31132324, 31142224,
    31214244, 31221122,
    31234431, 31244224, 31313422, 31323222, 31331234, 31342434, 31344234,
    31414234, 31422241,
    31432221, 31434111, 31434321, 31443224, 32111242, 32120214, 32123441,
    32132224, 32144244,
    32220144, 32221214, 32224222, 32224244, 32231242, 32243234, 32314222,
    32321442, 32343222,
    32412124, 32424232, 32424242, 32432124, 32432222, 32441232, 33141232,
    33221322, 33244232,
    33333333, 33412244, 33421234, 33422432, 33423121, 33441233, 34111244,
    34124244, 34134243,
    34143141, 34143144, 34210144, 34223221, 34223244, 34224224, 34234324,
    34241214, 34243131,
    34243212, 34314242, 34322112, 34334242, 34342414, 34343434, 34414442,
    34422142, 34423242,
    34424334, 34431243, 34432241, 34441441, 34442122, 34443234, 34444122,
    41112442, 41122442,
    41124122, 41132432, 41142244, 41144141, 41144442, 41212121, 41213244,
    41213422, 41224124,
    41224224, 41224334, 41231242, 41242214, 41244432, 41311222, 41313222,
    41313442, 41324211,
    41334223, 41341222, 41341222, 41342214, 41344441, 41412121, 41421442,
    41422334, 41434144,
    41442434, 42000024, 42024232, 42111412, 42123241, 42131212, 42142244,
    42212412, 42221124,
    42221222, 42222232, 42223432, 42232414, 42233223, 42241212, 42313422,
    42323244, 42323422,
    42324244, 42333422, 42333442, 42342341, 42344241, 42412444, 42413121,
    42421424, 42422424,
    42423232, 42424141, 42424444, 42433124, 42441111, 42441222, 42441232,
    42622462, 42624422,
    43114443, 43122224, 43124114, 43131324, 43134144, 43142212, 43144344,
    43214321, 43221432,
    43232442, 43244322, 43313443, 43323212, 43323212, 43324224, 43334413,
    43342222, 43342432,
    43344334, 43414422, 43421121, 43424242, 43434142, 43434144, 43434442,
    43444422, 44004400,
    44112412, 44113231, 44121224, 44134122, 44134324, 44143322, 44213242,
    44221144, 44234124,
    44234232, 44243422, 44314123, 44322124, 44334242, 44334343, 44342232,
    44342412, 44414224,
    44421242, 44421421, 44421424, 44431421, 44432424, 44441212, 44444242,
    12345678, 13287282,
    26345664, 26722884, 27282827, 27382738, 27384856, 34567812, 36178242,
    36377284, 36383836,
    36546644, 37483847, 41828446, 42273881, 42428822, 42646246, 45226644,
    45434666, 45544256,
    45565254, 45634566, 46266464, 46352226, 46466433, 46514416, 46544346,
    46544654, 46545253,
    46611454, 46636546, 46727861, 46848126, 47484748, 47626684, 48422614,
    48424841, 51144446,
    51263462, 51325455, 51446454, 51546634, 51563652, 51616151, 51644243,
    51644633, 52145236,
    52222553, 52344664, 52465354, 52466446, 52545256, 52564464, 52566465,
    52664654, 52824574,
    52828252, 53164266, 53261146, 53364463, 53426426, 53464345, 53536564,
    53623456, 53634434,
    53665364, 53816273, 54354662, 54365636, 54424262, 54445464, 54466344,
    54546444, 54613546,
    54633426, 54644554, 54647484, 55266536, 55446446, 55546256, 55555555,
    55556666, 56266411,
    56344624, 56366644, 56434663, 56645264, 56646264, 57356365, 57386575,
    61144246, 61243256,
    61345524, 61366442, 61446256, 61452663, 61465462, 61465642, 61487462,
    61515162, 61546264,
    61555464, 61626364, 61644644, 61645245, 62246654, 62446264, 62544564,
    62545366, 62546455,
    62624554, 62648628, 62666461, 62726574, 63266454, 63286212, 63364224,
    63366254, 63446264,
    62545564, 63626263, 63636266, 64162446, 64252546, 64354462, 64365636,
    64415264, 64436544,
    64446264, 64446534, 64534244, 64636261, 64644554, 64668571, 64828241,
    65345261, 65432884,
    65436543, 65446264, 65526244, 65533264, 65536266, 65464838, 65784231,
    65837244, 66162444,
    66226644, 66245544, 66344661, 66365254, 66444264, 66446264, 66446644,
    66526652, 66566424,
    66576658, 66635246, 66644624, 66665656, 66666868, 66872244, 67184718,
    67442786, 67822674,
    68166264, 68284821, 68426842, 68626448, 68628448, 71288472, 71528364,
    72484846, 72527252,
    72727474, 72737475, 72747678, 72774848, 72816384, 73747526, 73836283,
    74737271, 74846484,
    75227641, 75318642, 75717472, 75737274, 76677484, 76737321, 77447722,
    77665544, 77784846,
    78167264, 78332364, 78767684, 78787274, 81417181, 81828281, 81828384,
    82222534, 82246116,
    82264224, 82624242, 82645731, 82727282, 82747816, 82828484, 82848688,
    83325375, 83737383,
    83828482, 83848483, 84622884, 84627181, 84627531, 84644221, 84682866,
    84822221, 84838281,
    84841111, 85243642, 85737583, 85847372, 85848182, 85858686, 85868283,
    86442221, 86838321,
    87766554, 88228822, 88646261, 88824442, 88888888, 44444444,
]

type
    Vertex = object
        position, normal, color, texture: Vec3[float64]

    SphericalHarmonics* = object
        n, size, color_map: int
        code: seq[float64]
        shape: seq[Vertex]
        faces: seq[array[4, int]]

proc code_2_vec(code: int): seq[float64] =
    var
        m = SPHERICAL_HARMONICS_CODES[code %% SPHERICAL_HARMONICS_CODES.len]
        v = newSeq[float64](8)

    for i in 0..<8:
        v[7 - i] = float64(m %% 10)
        m = m div 10

    result = v

proc calc_vertex(code: seq[float64], theta: float64, phi: float64): Vec3[float64] =
    let r = (code[0] * phi).sin().pow(code[1]) +
            (code[2] * phi).cos().pow(code[3]) +
            (code[4] * theta).sin().pow(code[5]) +
            (code[6] * theta).cos().pow(code[7])

    result = vec3(
        r * phi.sin() * theta.cos(),
        r * phi.cos(),
        r * phi.sin() * theta.sin(),
    )

proc calc_normal(v0: Vec3[float64], v1: Vec3[float64], v2: Vec3[float64]): Vec3[float64] =
    let n = (v2 - v0).cross(v1 - v0)
    result = if n == vec3(0.0, 0.0, 0.0): n else: n.normalize()

proc calc_color(vp: float64, vmin: float64, vmax: float64, cm: int): Vec3[float64] =
    let
        zv = vec3(0.0, 0.0, 0.0)

    var
        vmid: float64 = 0.0
        ratio: float64 = 0.0
        dv: float64
        c = vec3(1.0, 1.0, 1.0)
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
        vmin -= 1.0
        vmax += 1.0

    if v < vmin: v = vmin
    if v > vmax: v = vmax
    dv = vmax - vmin

    case cm:
        of 0..1:
            if v < (vmin + 0.25 * dv):
                c = vec3(0.0, 4.0 * (v - vmin) / dv, 1.0)
            elif v < (vmin + 0.5 * dv):
                c = vec3(0.0, 1.0, 1.0 + 4.0 * (vmin + 0.25 * dv - v) / dv)
            elif v < (vmin + 0.75 * dv):
                c.r = 4.0 * (v - vmin - 0.5 * dv) / dv
                c.g = 1.0
                c.b = 0.0
            else:
                c.r = 1.0
                c.g = 1.0 + 4.0 * (vmin + 0.75 * dv - v) / dv
                c.b = 0.0
        of 2:
            c.r = (v - vmin) / dv
            c.g = 0.0
            c.b = (vmax - v) / dv
        of 3:
            c.r = (v - vmin) / dv
            c.b = c.r
            c.g = c.r

        of 4:
            if v < (vmin + dv / 6.0):
                c.r = 1
                c.g = 6 * (v - vmin) / dv
                c.b = 0
            elif v < (vmin + 2.0 * dv / 6.0):
                c.r = 1 + 6 * (vmin + dv / 6.0 - v) / dv
                c.g = 1
                c.b = 0
            elif v < (vmin + 3.0 * dv / 6.0):
                c.r = 0
                c.g = 1
                c.b = 6 * (v - vmin - 2.0 * dv / 6.0) / dv
            elif v < (vmin + 4.0 * dv / 6.0):
                c.r = 0
                c.g = 1 + 6 * (vmin + 3.0 * dv / 6.0 - v) / dv
                c.b = 1
            elif v < (vmin + 5.0 * dv / 6.0):
                c.r = 6 * (v - vmin - 4.0 * dv / 6.0) / dv
                c.g = 0
                c.b = 1
            else:
                c.r = 1
                c.g = 0
                c.b = 1 + 6 * (vmin + 5.0 * dv / 6.0 - v) / dv
        of 5:
            c.r = (v - vmin) / (vmax - vmin)
            c.g = 1
            c.b = 0
        of 6:
            c.r = (v - vmin) / (vmax - vmin)
            c.g = (vmax - v) / (vmax - vmin)
            c.b = c.r
        of 7:
            if v < (vmin + 0.25 * dv):
                c.r = 0
                c.g = 4 * (v - vmin) / dv
                c.b = 1 - c.g
            elif v < (vmin + 0.5 * dv):
                c.r = 4 * (v - vmin - 0.25 * dv) / dv
                c.g = 1 - c.r
                c.b = 0
            elif v < (vmin + 0.75 * dv):
                c.g = 4 * (v - vmin - 0.5 * dv) / dv
                c.r = 1 - c.g
                c.b = 0
            else:
                c.r = 0
                c.b = 4 * (v - vmin - 0.75 * dv) / dv
                c.g = 1 - c.b
        of 8:
            if v < (vmin + 0.5 * dv):
                c.r = 2 * (v - vmin) / dv
                c.g = c.r
                c.b = c.r
            else:
                c.r = 1 - 2 * (v - vmin - 0.5 * dv) / dv
                c.g = c.r
                c.b = c.r
        of 9:
            if v < (vmin + dv / 3):
                c.b = 3 * (v - vmin) / dv
                c.g = 0
                c.r = 1 - c.b
            elif v < (vmin + 2 * dv / 3):
                c.r = 0
                c.g = 3 * (v - vmin - dv / 3) / dv
                c.b = 1
            else:
                c.r = 3 * (v - vmin - 2 * dv / 3) / dv
                c.g = 1 - c.r
                c.b = 1
        of 10:
            if v < (vmin + 0.2 * dv):
                c.r = 0
                c.g = 5 * (v - vmin) / dv
                c.b = 1
            elif v < (vmin + 0.4 * dv):
                c.r = 0
                c.g = 1
                c.b = 1 + 5 * (vmin + 0.2 * dv - v) / dv
            elif v < (vmin + 0.6 * dv):
                c.r = 5 * (v - vmin - 0.4 * dv) / dv
                c.g = 1
                c.b = 0
            elif v < (vmin + 0.8 * dv):
                c.r = 1
                c.g = 1 - 5 * (v - vmin - 0.6 * dv) / dv
                c.b = 0
            else:
                c.r = 1
                c.g = 5 * (v - vmin - 0.8 * dv) / dv
                c.b = 5 * (v - vmin - 0.8 * dv) / dv
        of 11:
            c1.r = 200 / 255.0
            c1.g = 60 / 255.0
            c1.b = 0 / 255.0
            c2.r = 250 / 255.0
            c2.g = 160 / 255.0
            c2.b = 110 / 255.0
            c.r = (c2.r - c1.r) * (v - vmin) / dv + c1.r
            c.g = (c2.g - c1.g) * (v - vmin) / dv + c1.g
            c.b = (c2.b - c1.b) * (v - vmin) / dv + c1.b
        of 12:
            c1.r = 55 / 255.0
            c1.g = 55 / 255.0
            c1.b = 45 / 255.0
            ##  c2.r = 200 / 255.0; c2.g =  60 / 255.0; c2.b =   0 / 255.0;
            c2.r = 235 / 255.0
            c2.g = 90 / 255.0
            c2.b = 30 / 255.0
            c3.r = 250 / 255.0
            c3.g = 160 / 255.0
            c3.b = 110 / 255.0
            ratio = 0.4
            vmid = vmin + ratio * dv
            if v < vmid:
                c.r = (c2.r - c1.r) * (v - vmin) / (ratio * dv) + c1.r
                c.g = (c2.g - c1.g) * (v - vmin) / (ratio * dv) + c1.g
                c.b = (c2.b - c1.b) * (v - vmin) / (ratio * dv) + c1.b
            else:
                c.r = (c3.r - c2.r) * (v - vmid) / ((1 - ratio) * dv) + c2.r
                c.g = (c3.g - c2.g) * (v - vmid) / ((1 - ratio) * dv) + c2.g
                c.b = (c3.b - c2.b) * (v - vmid) / ((1 - ratio) * dv) + c2.b
        of 13:
            c1.r = 0 / 255.0
            c1.g = 255 / 255.0
            c1.b = 0 / 255.0
            c2.r = 255 / 255.0
            c2.g = 150 / 255.0
            c2.b = 0 / 255.0
            c3.r = 255 / 255.0
            c3.g = 250 / 255.0
            c3.b = 240 / 255.0
            ratio = 0.3
            vmid = vmin + ratio * dv
            if v < vmid:
                c.r = (c2.r - c1.r) * (v - vmin) / (ratio * dv) + c1.r
                c.g = (c2.g - c1.g) * (v - vmin) / (ratio * dv) + c1.g
                c.b = (c2.b - c1.b) * (v - vmin) / (ratio * dv) + c1.b
            else:
                c.r = (c3.r - c2.r) * (v - vmid) / ((1 - ratio) * dv) + c2.r
                c.g = (c3.g - c2.g) * (v - vmid) / ((1 - ratio) * dv) + c2.g
                c.b = (c3.b - c2.b) * (v - vmid) / ((1 - ratio) * dv) + c2.b
        of 14:
            c.r = 1
            c.g = 1 - (v - vmin) / dv
            c.b = 0
        of 15:
            if v < (vmin + 0.25 * dv):
                c.r = 0
                c.g = 4 * (v - vmin) / dv
                c.b = 1
            elif v < (vmin + 0.5 * dv):
                c.r = 0
                c.g = 1
                c.b = 1 - 4 * (v - vmin - 0.25 * dv) / dv
            elif v < (vmin + 0.75 * dv):
                c.r = 4 * (v - vmin - 0.5 * dv) / dv
                c.g = 1
                c.b = 0
            else:
                c.r = 1
                c.g = 1
                c.b = 4 * (v - vmin - 0.75 * dv) / dv
        of 16:
            if v < (vmin + 0.5 * dv):
                c.r = 0.0
                c.g = 2 * (v - vmin) / dv
                c.b = 1 - 2 * (v - vmin) / dv
            else:
                c.r = 2 * (v - vmin - 0.5 * dv) / dv
                c.g = 1 - 2 * (v - vmin - 0.5 * dv) / dv
                c.b = 0.0
        of 17:
            if v < (vmin + 0.5 * dv):
                c.r = 1.0
                c.g = 1 - 2 * (v - vmin) / dv
                c.b = 2 * (v - vmin) / dv
            else:
                c.r = 1 - 2 * (v - vmin - 0.5 * dv) / dv
                c.g = 2 * (v - vmin - 0.5 * dv) / dv
                c.b = 1.0
        of 18:
            c.r = 0
            c.g = (v - vmin) / (vmax - vmin)
            c.b = 1
        of 19:
            c.r = (v - vmin) / (vmax - vmin)
            c.g = c.r
            c.b = 1
        of 20:
            c1.r = 0 / 255.0
            c1.g = 160 / 255.0
            c1.b = 0 / 255.0
            c2.r = 180 / 255.0
            c2.g = 220 / 255.0
            c2.b = 0 / 255.0
            c3.r = 250 / 255.0
            c3.g = 220 / 255.0
            c3.b = 170 / 255.0
            ratio = 0.3
            vmid = vmin + ratio * dv
            if v < vmid:
                c.r = (c2.r - c1.r) * (v - vmin) / (ratio * dv) + c1.r
                c.g = (c2.g - c1.g) * (v - vmin) / (ratio * dv) + c1.g
                c.b = (c2.b - c1.b) * (v - vmin) / (ratio * dv) + c1.b
            else:
                c.r = (c3.r - c2.r) * (v - vmid) / ((1 - ratio) * dv) + c2.r
                c.g = (c3.g - c2.g) * (v - vmid) / ((1 - ratio) * dv) + c2.g
                c.b = (c3.b - c2.b) * (v - vmid) / ((1 - ratio) * dv) + c2.b
        of 21:
            c1.r = 255 / 255.0
            c1.g = 255 / 255.0
            c1.b = 200 / 255.0
            c2.r = 150 / 255.0
            c2.g = 150 / 255.0
            c2.b = 255 / 255.0
            c.r = (c2.r - c1.r) * (v - vmin) / dv + c1.r
            c.g = (c2.g - c1.g) * (v - vmin) / dv + c1.g
            c.b = (c2.b - c1.b) * (v - vmin) / dv + c1.b
        of 22:
            c.r = 1 - (v - vmin) / dv
            c.g = 1 - (v - vmin) / dv
            c.b = (v - vmin) / dv
        of 23:
            if v < (vmin + 0.5 * dv):
                c.r = 1
                c.g = 2 * (v - vmin) / dv
                c.b = c.g
            else:
                c.r = 1 - 2 * (v - vmin - 0.5 * dv) / dv
                c.g = c.r
                c.b = 1
        of 24:
            if v < (vmin + 0.5 * dv):
                c.r = 2 * (v - vmin) / dv
                c.g = c.r
                c.b = 1 - c.r
            else:
                c.r = 1
                c.g = 1 - 2 * (v - vmin - 0.5 * dv) / dv
                c.b = 0
        of 25:
            if v < (vmin + dv / 3):
                c.r = 0
                c.g = 3 * (v - vmin) / dv
                c.b = 1
            elif v < (vmin + 2 * dv / 3):
                c.r = 3 * (v - vmin - dv / 3) / dv
                c.g = 1 - c.r
                c.b = 1
            else:
                c.r = 1
                c.g = 0
                c.b = 1 - 3 * (v - vmin - 2 * dv / 3) / dv
        else:
            c = zv
    c

proc set_vertex(sh: var SphericalHarmonics, index: int) =
    const PI2 = PI * 2.0
    let
        dx = 1.0 / float64(sh.n)
        du = PI2 * dx # Theta
        dv = PI * dx  # Phi
        i = index div sh.n
        j = index %% sh.n
        u = du * float64(i)
        v = dv * float64(j)
        color_offset = if (i and 1) == 0: u else: u + du

    let
        position = calc_vertex(sh.code, u, v)
        normal = calc_normal(
            position,
            calc_vertex(sh.code, u + du, v),
            calc_vertex(sh.code, u, v + dv),
        )
        color = calc_color(color_offset, 0.0, PI2, sh.color_map)
        texture = vec3(float64(i) * dx, float64(j) * dx, 0.0)

    sh.shape[index]=Vertex(position: position, normal: normal, color: color,
            texture: texture)


proc generate_mt(sh: var SphericalHarmonics) = # multithread generator
  sh.shape = newSeq[Vertex](sh.size)

  Weave.init()

  let sh_ptr = sh.addr
  parallelFor index in 0..<sh.size:
    captures: {sh_ptr}
    sh_ptr[].set_vertex(index)

  Weave.exit()

proc triangularize(f:array[4,int]):array[2, array[3,int]] =
  for i,t in [[0,1,2],[0,2,3]].pairs:  
    result[i]=[ f[t[0]], f[t[1]], f[t[2]] ]

proc generate_faces(sh: var SphericalHarmonics) =
  let n = sh.n
  for i in 0..<n - 1:
    for j in 0..<n - 1:
      sh.faces.add [(i + 1) * n + j, (i + 1) * n + j + 1,  i * n + j + 1, i * n + j ]
    sh.faces.add [(i + 1) * n, (i + 1) * n + n - 1, i * n, i * n + n - 1]

  for i in 0..<n - 1:
    sh.faces.add [i, i + 1, n * (n - 1) + i + 1, n * (n - 1) + i]

proc newSH*(n: int, code: int, color_map: int): SphericalHarmonics =
  result = SphericalHarmonics(
            n: n, size: n*n, 
            code: code_2_vec(code %% SPHERICAL_HARMONICS_CODES.len), color_map: color_map )
  result.generate_mt()
  result.generate_faces()

proc print(sh: SphericalHarmonics) =
  for v in sh.shape:
      echo v.position, v.normal, v.color, v.texture
  for face in sh.faces:
      echo face

proc write_plyxx(sh : SphericalHarmonics, file_name : string)=
  var st = newFileStream(file_name, fmWrite)
  st.write &"""ply
format ascii 1.0
comment spherical harmonics {sh.code}
element vertex {sh.shape.len}
property float x
property float y
property float z
property float nx
property float ny
property float nz
property uchar red
property uchar green
property uchar blue
element face {sh.faces.len*2}
property list uchar int vertex_indices
end_header
"""

  proc toString(v:Vec3[float64]):string = &"{v.x:.3} {v.y:.3} {v.z:.3}"
  proc toString8(v:Vec3[float64]):string = &"{(v.x*255).int} {(v.y*255).int} {(v.z*255).int}"

  for v in sh.shape: st.write v.position.toString & " " & v.normal.toString & " " &  v.color.toString8 & "\n"
  for f in sh.faces: # triangularize faces
    for t in f.triangularize:  st.write &"3 {t[0]} {t[1]} {t[2]}\n"

  st.close

type  PlyFileType* = enum ftBinary, ftAscii 

proc write_ply(sh : SphericalHarmonics, file_name : string, file_type : PlyFileType = ftBinary)=
  var fh = open(file_name, fmWrite, bufSize=4096)
  let ba = if file_type==ftBinary: "binary_little_endian" else: "ascii"

  fh.write &"""ply
format {ba} 1.0
comment spherical harmonics {sh.code}
element vertex {sh.shape.len}
property float x
property float y
property float z
property float nx
property float ny
property float nz
property uchar red
property uchar green
property uchar blue
element face {sh.faces.len*2}
property list uchar int vertex_indices
end_header
"""

  case file_type:

  of ftBinary: 
    var bf : seq[uint8]

    for v in sh.shape:
      for i in 0..2: bf.add cast[array[4,uint8]](v.position[i].float32)
      for i in 0..2: bf.add cast[array[4,uint8]](v.normal[i].float32)
      for i in 0..2: bf.add (v.color[i]*255).uint8
    var bw = fh.writeBuffer(bf[0].addr, bf.len)
    assert bw == bf.len, "write error"
    

    bf.setLen 0
    for f in sh.faces:
      for t in f.triangularize:
        bf.add 3
        for i in t:
          for b in cast[array[4,uint8]](i): bf.add b

    bw = fh.writeBuffer(bf[0].addr, bf.len)
    assert bw == bf.len, "write error"

  of ftAscii: # ascii 
    proc toString(v:Vec3[float64]):string = &"{v.x:.3} {v.y:.3} {v.z:.3} "
    proc toString8(v:Vec3[float64]):string = &"{(v.x*255).int} {(v.y*255).int} {(v.z*255).int}"

    for v in sh.shape: fh.write v.position.toString & v.normal.toString & v.color.toString8 & "\n"
    for f in sh.faces: # triangularize faces
      for t in f.triangularize:  fh.write &"3 {t[0]} {t[1]} {t[2]}\n"

  fh.close


proc write_wrl(sh: SphericalHarmonics, name: string) =
    var f = newFileStream(name, fmWrite)


    if not f.isNil:
        f.write("""
#VRML V2.0 utf8 

# Spherical Harmonics :        

# lights on
DirectionalLight {  direction -.5 -1 0   intensity 1  color 1 1 1 }
DirectionalLight {  direction  .5  1 0   intensity 1  color 1 1 1 }
           
Shape {
    # default material
    appearance Appearance {
        material Material { }
    }
    geometry IndexedFaceSet {
        
        coord Coordinate {
            point [
""")

        for s in sh.shape:
            let p = s.position
            f.write(p.x, " ", p.y, " ", p.z, "\n")

        f.write(
            """]
        }
        color Color {
            color [
            """)

        for s in sh.shape:
            let p = s.color
            f.write(p.x, " ", p.y, " ", p.z, "\n")

        f.write(
            """]
        }
        normal Normal {
            vector [
        """)

        #  normals
        for s in sh.shape:
            let p = s.normal
            f.write(p.x, " ", p.y, " ", p.z, "\n")
        f.write(
            """]
        }
        coordIndex [
            """)
        #  faces
        for face in sh.faces:
            for ix in face:
                f.write($ix, " ")

            f.write("-1,\n")

        f.write(
            """]
        colorPerVertex TRUE
        convex TRUE
        solid TRUE
    }
}""")
        f.close()


when isMainModule:
    var t0 = now()

    let
        resolution = 128 * 1
        code = 176
        color_map = 0

    echo fmt("sh {resolution}x{resolution}={resolution*resolution}...")
    var sh = newSH(resolution, code, color_map)

    echo fmt("lap:{(now() - t0).inMilliseconds()}ms, writing...")

    sh.write_ply("sh.ply", ftBinary)

