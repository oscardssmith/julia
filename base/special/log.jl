# This file is a part of Julia. License is MIT: https://julialang.org/license

# Implementation of
#  "Table-driven Implementation of the Logarithm Function in IEEE Floating-point Arithmetic"
#  Tang, Ping-Tak Peter
#  ACM Trans. Math. Softw. (1990), 16(4):378--400
#  https://doi.org/10.1145/98267.98294

# Does not currently handle floating point flags (inexact, div-by-zero, etc).

import .Base.unsafe_trunc
import .Base.Math.@horner

# Float64 lookup table.
# to generate values:
  # N=39 # (can be up to N=42).
  # sN = 2.0^N
  # isN = 1.0/sN
  # s7 = 2.0^7
  # is7 = 1.0/s7
  # for j=0:128
  #   l_big = Base.log(big(1.0+j*is7))
  #   l_hi = isN*Float64(round(sN*l_big))
  #   l_lo = Float64(l_big-l_hi)
  #   j % 2 == 0 && print("\n    ")
  #   print("(",l_hi,",",l_lo,"),")
  # end

const t_log_Float64 = ((0.0,0.0),(0.007782140442941454,-8.865052917267247e-13),
    (0.015504186536418274,-4.530198941364935e-13),(0.0231670592820592,-5.248209479295644e-13),
    (0.03077165866670839,4.529814257790929e-14),(0.0383188643027097,-5.730994833076631e-13),
    (0.04580953603181115,-5.16945692881222e-13),(0.053244514518155484,6.567993368985218e-13),
    (0.06062462181580486,6.299848199383311e-13),(0.06795066190898069,-4.729424109166329e-13),
    (0.07522342123775161,-1.6408301585598662e-13),(0.08244366921098845,8.614512936087814e-14),
    (0.08961215869021544,-5.283050530808144e-13),(0.09672962645890948,-3.5836667430094137e-13),
    (0.10379679368088546,7.581073923016376e-13),(0.11081436634049169,-2.0157368416016215e-13),
    (0.11778303565552051,8.629474042969438e-13),(0.1247034785010328,-7.556920687451337e-14),
    (0.1315763577895268,-8.075373495358435e-13),(0.13840232285838283,7.363043577087051e-13),
    (0.14518200984457508,-7.718001336828099e-14),(0.15191604202664166,-7.996871607743758e-13),
    (0.15860503017574956,8.890223439724663e-13),(0.16524957289584563,-5.384682618788232e-13),
    (0.17185025692742784,-7.686134224018169e-13),(0.17840765747314435,-3.2605717931058157e-13),
    (0.18492233849428885,-2.7685884310448306e-13),(0.1913948530000198,-3.903387893794952e-13),
    (0.1978257433293038,6.160755775588723e-13),(0.20421554142922105,-5.30156516006026e-13),
    (0.21056476910780475,-4.55112422774782e-13),(0.21687393830143264,-8.182853292737783e-13),
    (0.22314355131493357,-7.238189921749681e-13),(0.22937410106533207,-4.86240001538379e-13),
    (0.23556607131286,-9.30945949519689e-14),(0.24171993688651128,6.338907368997553e-13),
    (0.24783616390413954,4.4171755371315547e-13),(0.25391520998164196,-6.785208495970588e-13),
    (0.25995752443668607,2.3999540484211735e-13),(0.2659635484978935,-7.555569400283742e-13),
    (0.27193371548310097,5.407904186145515e-13),(0.2778684510030871,3.692037508208009e-13),
    (0.28376817313073843,-9.3834172236637e-14),(0.28963329258294834,9.43339818951269e-14),
    (0.29546421289342106,4.148131870425857e-13),(0.3012613305781997,-3.7923164802093147e-14),
    (0.3070250352957373,-8.25463138725004e-13),(0.31275571000333,5.668653582900739e-13),
    (0.318453731119007,-4.723727821986367e-13),(0.32411946865431673,-1.0475750058776541e-13),
    (0.32975328637257917,-1.1118671389559323e-13),(0.33535554192167183,-5.339989292003297e-13),
    (0.3409265869704541,1.3912841212197566e-13),(0.3464667673470103,-8.017372713972018e-13),
    (0.35197642315688427,2.9391859187648e-13),(0.3574558889213222,4.815896111723205e-13),
    (0.3629054936900502,-6.817539406325327e-13),(0.36832556115950865,-8.009990055432491e-13),
    (0.3737164097929053,6.787566823158706e-13),(0.37907835293481185,1.5761203773969435e-13),
    (0.3844116989112081,-8.760375990774874e-13),(0.38971675114044046,-4.152515806343612e-13),
    (0.3949938082405424,3.2655698896907146e-13),(0.40024316412745975,-4.4704265010452445e-13),
    (0.4054651081078191,3.452764795203977e-13),(0.4106599249844294,8.390050778518307e-13),
    (0.4158278951435932,1.1776978751369214e-13),(0.4209692946442374,-1.0774341461609579e-13),
    (0.42608439531068143,2.186334329321591e-13),(0.43117346481813,2.413263949133313e-13),
    (0.4362367667745275,3.90574622098307e-13),(0.44127456080423144,6.437879097373207e-13),
    (0.44628710262804816,3.713514191959202e-13),(0.45127464413963025,-1.7166921336082432e-13),
    (0.4562374334818742,-2.8658285157914353e-13),(0.4611757151214988,6.713692791384601e-13),
    (0.46608972992544295,-8.437281040871276e-13),(0.4709797152190731,-2.821014384618127e-13),
    (0.4758459048698569,1.0701931762114255e-13),(0.4806885293455707,1.8119346366441111e-13),
    (0.4855078157816024,9.840465278232627e-14),(0.49030398804461583,5.780031989454028e-13),
    (0.49507726679803454,-1.8302857356041668e-13),(0.4998278695566114,-1.620740015674495e-13),
    (0.5045560107519123,4.83033149495532e-13),(0.5092619017905236,-7.156055317238212e-13),
    (0.5139457511013461,8.882123951857185e-13),(0.5186077642083546,-3.0900580513238243e-13),
    (0.5232481437651586,-6.10765519728515e-13),(0.5278670896204858,3.565996966334783e-13),
    (0.532464798869114,3.5782396591276384e-13),(0.5370414658973459,-4.622608700154458e-13),
    (0.5415972824321216,6.227976291722515e-13),(0.5461324375974073,7.283894727206574e-13),
    (0.5506471179523942,2.680964661521167e-13),(0.5551415075406112,-1.0960825046059278e-13),
    (0.5596157879353996,2.3119493838005378e-14),(0.5640701382853877,-5.846905800529924e-13),
    (0.5685047353526897,-2.1037482511444942e-14),(0.5729197535620187,-2.332318294558741e-13),
    (0.5773153650352469,-4.2333694288141915e-13),(0.5816917396350618,-4.3933937969737843e-13),
    (0.5860490450031648,4.1341647073835564e-13),(0.590387446602108,6.841763641591467e-14),
    (0.5947071077462169,4.758553400443064e-13),(0.5990081896452466,8.367967867475769e-13),
    (0.6032908514389419,-8.576373464665864e-13),(0.6075552502243227,2.1913281229340092e-13),
    (0.6118015411066153,-6.224284253643115e-13),(0.6160298772156239,-1.098359432543843e-13),
    (0.6202404097512044,6.531043137763365e-13),(0.6244332880123693,-4.758019902171077e-13),
    (0.6286086594227527,-3.785425126545704e-13),(0.6327666695706284,4.0939233218678666e-13),
    (0.636907462236195,8.742438391485829e-13),(0.6410311794206791,2.521818845684288e-13),
    (0.6451379613736208,-3.6081313604225574e-14),(0.649227946625615,-5.05185559242809e-13),
    (0.6533012720119586,7.869940332335532e-13),(0.6573580727090302,-6.702087696194906e-13),
    (0.6613984822452039,1.6108575753932459e-13),(0.6654226325445052,5.852718843625151e-13),
    (0.6694306539429817,-3.5246757297904794e-13),(0.6734226752123504,-1.8372084495629058e-13),
    (0.6773988235909201,8.860668981349492e-13),(0.6813592248072382,6.64862680714687e-13),
    (0.6853040030982811,6.383161517064652e-13),(0.6892332812385575,2.5144230728376075e-13),
    (0.6931471805601177,-1.7239444525614835e-13))

# Float32 lookup table
# to generate values:
  # N=16
  # sN = 2f0^N
  # isN = 1f0/sN
  # s7 = 2.0^7
  # is7 = 1.0/s7
  # for j=0:128
  #   j % 4 == 0 && print("\n    ")
  #   print(float64(Base.log(big(1.0+j*is7))),",")
  # end

const t_log_Float32 = (0.0,0.007782140442054949,0.015504186535965254,0.02316705928153438,
    0.030771658666753687,0.0383188643021366,0.0458095360312942,0.053244514518812285,
    0.06062462181643484,0.06795066190850775,0.07522342123758753,0.08244366921107459,
    0.08961215868968714,0.09672962645855111,0.10379679368164356,0.11081436634029011,
    0.11778303565638346,0.12470347850095724,0.13157635778871926,0.13840232285911913,
    0.1451820098444979,0.15191604202584197,0.15860503017663857,0.16524957289530717,
    0.17185025692665923,0.1784076574728183,0.184922338494012,0.19139485299962947,
    0.19782574332991987,0.2042155414286909,0.21056476910734964,0.21687393830061436,
    0.22314355131420976,0.22937410106484582,0.2355660713127669,0.24171993688714516,
    0.24783616390458127,0.25391520998096345,0.25995752443692605,0.26596354849713794,
    0.27193371548364176,0.2778684510034563,0.2837681731306446,0.28963329258304266,
    0.2954642128938359,0.3012613305781618,0.3070250352949119,0.3127557100038969,
    0.3184537311185346,0.324119468654212,0.329753286372468,0.3353555419211378,
    0.3409265869705932,0.34646676734620857,0.3519764231571782,0.3574558889218038,
    0.3629054936893685,0.3683255611587076,0.37371640979358406,0.37907835293496944,
    0.38441169891033206,0.3897167511400252,0.394993808240869,0.4002431641270127,
    0.4054651081081644,0.4106599249852684,0.415827895143711,0.42096929464412963,
    0.4260843953109001,0.4311734648183713,0.43623676677491807,0.4412745608048752,
    0.44628710262841953,0.45127464413945856,0.4562374334815876,0.46117571512217015,
    0.46608972992459924,0.470979715218791,0.4758459048699639,0.4806885293457519,
    0.4855078157817008,0.4903039880451938,0.4950772667978515,0.4998278695564493,
    0.5045560107523953,0.5092619017898079,0.5139457511022343,0.5186077642080457,
    0.5232481437645479,0.5278670896208424,0.5324647988694718,0.5370414658968836,
    0.5415972824327444,0.5461324375981357,0.5506471179526623,0.5551415075405016,
    0.5596157879354227,0.564070138284803,0.5685047353526688,0.5729197535617855,
    0.5773153650348236,0.5816917396346225,0.5860490450035782,0.5903874466021763,
    0.5947071077466928,0.5990081896460834,0.6032908514380843,0.6075552502245418,
    0.6118015411059929,0.616029877215514,0.6202404097518576,0.6244332880118935,
    0.6286086594223741,0.6327666695710378,0.6369074622370692,0.6410311794209312,
    0.6451379613735847,0.6492279466251099,0.6533012720127457,0.65735807270836,
    0.661398482245365,0.6654226325450905,0.6694306539426292,0.6734226752121667,
    0.6773988235918061,0.6813592248079031,0.6853040030989194,0.689233281238809,
    0.6931471805599453)

# truncate lower order bits (up to 26)
# ideally, this should be able to use ANDPD instructions, see #9868.
@inline function truncbits(x::Float64)
    reinterpret(Float64, reinterpret(UInt64,x) & 0xffff_ffff_f800_0000)
end

logb(::Type{Float32},::Val{2})  = 1.4426950408889634
logb(::Type{Float32},::Val{:ℯ}) = 1.0
logb(::Type{Float32},::Val{10}) = 0.4342944819032518
logbU(::Type{Float64},::Val{2})  = 1.4426950408889634
logbL(::Type{Float64},::Val{2})  = 2.0355273740931033e-17
logbU(::Type{Float64},::Val{:ℯ}) = 1.0
logbL(::Type{Float64},::Val{:ℯ}) = 0.0
logbU(::Type{Float64},::Val{10}) = 0.4342944819032518
logbL(::Type{Float64},::Val{10}) = 1.098319650216765e-17

# Procedure 1
# XXX we want to mark :consistent-cy here so that this function can be concrete-folded,
# because the effect analysis currently can't prove it in the presence of `@inbounds` or
# `:boundscheck`, but still the access to `t_log_Float64` is really safe here
Base.@assume_effects :consistent @inline function log_proc1(y::Float64,mf::Float64,F::Float64,f::Float64,base=Val(:ℯ))
    jp = unsafe_trunc(Int,128.0*F)-127

    ## Steps 1 and 2
    @inbounds hi,lo = t_log_Float64[jp]
    l_hi = mf* 0.6931471805601177 + hi
    l_lo = mf*-1.7239444525614835e-13 + lo

    ## Step 3
    # @inbounds u = f*c_invF[jp]
    # u = f/F
    # q = u*u*@horner(u,
    #                 -0x1.0_0000_0000_0001p-1,
    #                 +0x1.5_5555_5550_9ba5p-2,
    #                 -0x1.f_ffff_ffeb_6526p-3,
    #                 +0x1.9_99b4_dfed_6fe4p-3,
    #                 -0x1.5_5576_6647_2e04p-3)

    ## Step 3' (alternative)
    u = (2.0f)/(y+F)
    v = u*u
    q = u*v*@horner(v,
                    0.08333333333303913,
                    0.012500053168098584)

    ## Step 4
    m_hi = logbU(Float64, base)
    m_lo = logbL(Float64, base)
    return fma(m_hi, l_hi, fma(m_hi, (u + (q + l_lo)), m_lo*l_hi))
end

# Procedure 2
@inline function log_proc2(f::Float64,base=Val(:ℯ))
    ## Step 1
    g = 1.0/(2.0+f)
    u = 2.0*f*g
    v = u*u

    ## Step 2
    q = u*v*@horner(v,
                    0.08333333333333179,
                    0.012500000003771751,
                    0.0022321399879194482,
                    0.0004348877777076146)

    ## Step 3
    # based on:
    #   2(f-u) = 2(f(2+f)-2f)/(2+f) = 2f^2/(2+f) = fu
    #   2(f-u1-u2) - f*(u1+u2) = 0
    #   2(f-u1) - f*u1 = (2+f)u2
    #   u2 = (2(f-u1) - f*u1)/(2+f)

    m_hi = logbU(Float64, base)
    m_lo = logbL(Float64, base)
    return fma(m_hi, u, fma(m_lo, u, m_hi*fma(fma(-u,f,2(f-u)), g, q)))
end

# Procedure 1
# XXX we want to mark :consistent-cy here so that this function can be concrete-folded,
# because the effect analysis currently can't prove it in the presence of `@inbounds` or
# `:boundscheck`, but still the access to `t_log_Float32` is really safe here
Base.@assume_effects :consistent @inline function log_proc1(y::Float32,mf::Float32,F::Float32,f::Float32,base=Val(:ℯ))
    jp = unsafe_trunc(Int,128.0f0*F)-127

    ## Steps 1 and 2
    @inbounds hi = t_log_Float32[jp]
    l = mf*0.6931471805599453 + hi

    ## Step 3
    # @inbounds u = f*c_invF[jp]
    # q = u*u*@horner(u,
    #                 Float32(-0x1.00006p-1),
    #                 Float32(0x1.55546cp-2))

    ## Step 3' (alternative)
    u = (2f0f)/(y+F)
    v = u*u
    q = u*v*0.08333351f0

    ## Step 4
    Float32(logb(Float32, base)*(l + (u + q)))
end

# Procedure 2
@inline function log_proc2(f::Float32,base=Val(:ℯ))
    ## Step 1
    # compute in higher precision
    u64 = Float64(2f0*f)/(2.0+f)
    u = Float32(u64)
    v = u*u

    ## Step 2
    q = u*v*@horner(v,
                    0.08333332f0,
                    0.012512346f0)

    ## Step 3: not required

    ## Step 4
    Float32(logb(Float32, base)*(u64 + q))
end

log2(x::Float32)  = _log(x, Val(2),  :log2)
log(x::Float32)   = _log(x, Val(:ℯ), :log)
log10(x::Float32) = _log(x, Val(10), :log10)
log2(x::Float64)  = _log(x, Val(2),  :log2)
log(x::Float64)   = _log(x, Val(:ℯ), :log)
log10(x::Float64) = _log(x, Val(10), :log10)

function _log(x::Float64, base, func)
    if x > 0.0
        x == Inf && return x

        # Step 2
        if 0.9394130628134757 < x < 1.0644944589178595
            f = x-1.0
            return log_proc2(f, base)
        end

        # Step 3
        xu = reinterpret(UInt64,x)
        m = Int(xu >> 52) & 0x07ff
        if m == 0 # x is subnormal
            x *= 1.8014398509481984e16 # 0x1p54, normalise significand
            xu = reinterpret(UInt64,x)
            m = Int(xu >> 52) & 0x07ff - 54
        end
        m -= 1023
        y = reinterpret(Float64,(xu & 0x000f_ffff_ffff_ffff) | 0x3ff0_0000_0000_0000)

        mf = Float64(m)
        F = (y + 3.5184372088832e13) - 3.5184372088832e13 # 0x1p-7*round(0x1p7*y)
        f = y-F

        return log_proc1(y,mf,F,f,base)
    elseif x == 0.0
        -Inf
    elseif isnan(x)
        NaN
    else
        throw_complex_domainerror(func, x)
    end
end

function _log(x::Float32, base, func)
    if x > 0f0
        x == Inf32 && return x

        # Step 2
        if 0.939413f0 < x < 1.0644945f0
            f = x-1f0
            return log_proc2(f, base)
        end

        # Step 3
        xu = reinterpret(UInt32,x)
        m = Int(xu >> 23) & 0x00ff
        if m == 0 # x is subnormal
            x *= 3.3554432f7 # 0x1p25, normalise significand
            xu = reinterpret(UInt32,x)
            m = Int(xu >> 23) & 0x00ff - 25
        end
        m -= 127
        y = reinterpret(Float32,(xu & 0x007f_ffff) | 0x3f80_0000)

        mf = Float32(m)
        F = (y + 65536.0f0) - 65536.0f0 # 0x1p-7*round(0x1p7*y)
        f = y-F

        log_proc1(y,mf,F,f,base)
    elseif x == 0f0
        -Inf32
    elseif isnan(x)
        NaN32
    else
        throw_complex_domainerror(func, x)
    end
end


function log1p(x::Float64)
    if x > -1.0
        x == Inf && return x
        if -1.1102230246251565e-16 < x < 1.1102230246251565e-16
            return x # Inexact

        # Step 2
        elseif -0.06058693718652422 < x < 0.06449445891785943
            return log_proc2(x)
        end

        # Step 3
        z = 1.0 + x
        zu = reinterpret(UInt64,z)
        s = reinterpret(Float64,0x7fe0_0000_0000_0000 - (zu & 0xfff0_0000_0000_0000)) # 2^-m
        m = Int(zu >> 52) & 0x07ff - 1023 # z cannot be subnormal
        c = m > 0 ? 1.0-(z-x) : x-(z-1.0) # 1+x = z+c exactly
        y = reinterpret(Float64,(zu & 0x000f_ffff_ffff_ffff) | 0x3ff0_0000_0000_0000)

        mf = Float64(m)
        F = (y + 3.5184372088832e13) - 3.5184372088832e13 # 0x1p-7*round(0x1p7*y)
        f = (y - F) + c*s #2^m(F+f) = 1+x = z+c

        log_proc1(y,mf,F,f)
    elseif x == -1.0
        -Inf
    elseif isnan(x)
        NaN
    else
        throw_complex_domainerror(:log1p, x)
    end
end

function log1p(x::Float32)
    if x > -1f0
        x == Inf32 && return x
        if -5.9604645f-8 < x < 5.9604645f-8
            return x # Inexact
        # Step 2
        elseif -0.06058694f0 < x < 0.06449446f0
            return log_proc2(x)
        end

        # Step 3
        z = 1f0 + x
        zu = reinterpret(UInt32,z)
        s = reinterpret(Float32,0x7f000000 - (zu & 0xff80_0000)) # 2^-m
        m = Int(zu >> 23) & 0x00ff - 127 # z cannot be subnormal
        c = m > 0 ? 1f0-(z-x) : x-(z-1f0) # 1+x = z+c
        y = reinterpret(Float32,(zu & 0x007f_ffff) | 0x3f80_0000)

        mf = Float32(m)
        F = (y + 65536.0f0) - 65536.0f0 # 0x1p-7*round(0x1p7*y)
        f = (y - F) + s*c #2^m(F+f) = 1+x = z+c

        log_proc1(y,mf,F,f)
    elseif x == -1f0
        -Inf32
    elseif isnan(x)
        NaN32
    else
        throw_complex_domainerror(:log1p, x)
    end
end

#function make_compact_table(N)
#    table = Tuple{UInt64,Float64}[]
#    lo, hi = 0x1.69555p-1, 0x1.69555p0
#    for i in 0:N-1
#        # I am not fully sure why this is the right formula to use, but it apparently is
#        center = i/(2*N) + lo < 1 ? (i+.5)/(2*N) + lo : (i+.5)/N + hi -1
#        invc = Float64(center < 1 ? round(N/center)/N : round(2*N/center)/(N*2))
#        c = inv(big(invc))
#        logc = Float64(round(0x1p43*log(c))/0x1p43)
#        logctail = reinterpret(Float64, Float64(log(c) - logc))
#        p1 = (reinterpret(UInt64,invc) >> 45) % UInt8
#        push!(table, (p1|reinterpret(UInt64,logc),logctail))
#    end
#    return Tuple(table)
#end
#const t_log_table_compact = make_compact_table(128)
const t_log_table_compact = (
    (0xbfd62c82f2b9c8b5, 5.929407345889625e-15),
    (0xbfd5d1bdbf5808b4, -2.544157440035963e-14),
    (0xbfd57677174558b3, -3.443525940775045e-14),
    (0xbfd51aad872df8b2, -2.500123826022799e-15),
    (0xbfd4be5f957778b1, -8.929337133850617e-15),
    (0xbfd4618bc21c60b0, 1.7625431312172662e-14),
    (0xbfd404308686a8af, 1.5688303180062087e-15),
    (0xbfd3a64c556948ae, 2.9655274673691784e-14),
    (0xbfd347dd9a9880ad, 3.7923164802093147e-14),
    (0xbfd2e8e2bae120ac, 3.993416384387844e-14),
    (0xbfd2895a13de88ab, 1.9352855826489123e-14),
    (0xbfd2895a13de88ab, 1.9352855826489123e-14),
    (0xbfd22941fbcf78aa, -1.9852665484979036e-14),
    (0xbfd1c898c16998a9, -2.814323765595281e-14),
    (0xbfd1675cababa8a8, 2.7643769993528702e-14),
    (0xbfd1058bf9ae48a7, -4.025092402293806e-14),
    (0xbfd0a324e27390a6, -1.2621729398885316e-14),
    (0xbfd0402594b4d0a5, -3.600176732637335e-15),
    (0xbfd0402594b4d0a5, -3.600176732637335e-15),
    (0xbfcfb9186d5e40a4, 1.3029797173308663e-14),
    (0xbfcef0adcbdc60a3, 4.8230289429940886e-14),
    (0xbfce27076e2af0a2, -2.0592242769647135e-14),
    (0xbfcd5c216b4fc0a1, 3.149265065191484e-14),
    (0xbfcc8ff7c79aa0a0, 4.169796584527195e-14),
    (0xbfcc8ff7c79aa0a0, 4.169796584527195e-14),
    (0xbfcbc286742d909f, 2.2477465222466186e-14),
    (0xbfcaf3c94e80c09e, 3.6507188831790577e-16),
    (0xbfca23bc1fe2b09d, -3.827767260205414e-14),
    (0xbfca23bc1fe2b09d, -3.827767260205414e-14),
    (0xbfc9525a9cf4509c, -4.7641388950792196e-14),
    (0xbfc87fa06520d09b, 4.9278276214647115e-14),
    (0xbfc7ab890210e09a, 4.9485167661250996e-14),
    (0xbfc7ab890210e09a, 4.9485167661250996e-14),
    (0xbfc6d60fe719d099, -1.5003333854266542e-14),
    (0xbfc5ff3070a79098, -2.7194441649495324e-14),
    (0xbfc5ff3070a79098, -2.7194441649495324e-14),
    (0xbfc526e5e3a1b097, -2.99659267292569e-14),
    (0xbfc44d2b6ccb8096, 2.0472357800461955e-14),
    (0xbfc44d2b6ccb8096, 2.0472357800461955e-14),
    (0xbfc371fc201e9095, 3.879296723063646e-15),
    (0xbfc29552f81ff094, -3.6506824353335045e-14),
    (0xbfc1b72ad52f6093, -5.4183331379008994e-14),
    (0xbfc1b72ad52f6093, -5.4183331379008994e-14),
    (0xbfc0d77e7cd09092, 1.1729485484531301e-14),
    (0xbfc0d77e7cd09092, 1.1729485484531301e-14),
    (0xbfbfec9131dbe091, -3.811763084710266e-14),
    (0xbfbe27076e2b0090, 4.654729747598445e-14),
    (0xbfbe27076e2b0090, 4.654729747598445e-14),
    (0xbfbc5e548f5bc08f, -2.5799991283069902e-14),
    (0xbfba926d3a4ae08e, 3.7700471749674615e-14),
    (0xbfba926d3a4ae08e, 3.7700471749674615e-14),
    (0xbfb8c345d631a08d, 1.7306161136093256e-14),
    (0xbfb8c345d631a08d, 1.7306161136093256e-14),
    (0xbfb6f0d28ae5608c, -4.012913552726574e-14),
    (0xbfb51b073f06208b, 2.7541708360737882e-14),
    (0xbfb51b073f06208b, 2.7541708360737882e-14),
    (0xbfb341d7961be08a, 5.0396178134370583e-14),
    (0xbfb341d7961be08a, 5.0396178134370583e-14),
    (0xbfb16536eea38089, 1.8195060030168815e-14),
    (0xbfaf0a30c0118088, 5.213620639136504e-14),
    (0xbfaf0a30c0118088, 5.213620639136504e-14),
    (0xbfab42dd71198087, 2.532168943117445e-14),
    (0xbfab42dd71198087, 2.532168943117445e-14),
    (0xbfa77458f632c086, -5.148849572685811e-14),
    (0xbfa77458f632c086, -5.148849572685811e-14),
    (0xbfa39e87b9fec085, 4.6652946995830086e-15),
    (0xbfa39e87b9fec085, 4.6652946995830086e-15),
    (0xbf9f829b0e780084, -4.529814257790929e-14),
    (0xbf9f829b0e780084, -4.529814257790929e-14),
    (0xbf97b91b07d58083, -4.361324067851568e-14),
    (0xbf8fc0a8b0fc0082, -1.7274567499706107e-15),
    (0xbf8fc0a8b0fc0082, -1.7274567499706107e-15),
    (0xbf7fe02a6b100081, -2.298941004620351e-14),
    (0xbf7fe02a6b100081, -2.298941004620351e-14),
    (0x0000000000000080, 0.0),
    (0x0000000000000080, 0.0),
    (0x3f8010157589007e, -1.4902732911301337e-14),
    (0x3f9020565893807c, -3.527980389655325e-14),
    (0x3f98492528c9007a, -4.730054772033249e-14),
    (0x3fa0415d89e74078, 7.580310369375161e-15),
    (0x3fa466aed42e0076, -4.9893776716773285e-14),
    (0x3fa894aa149fc074, -2.262629393030674e-14),
    (0x3faccb73cdddc072, -2.345674491018699e-14),
    (0x3faeea31c006c071, -1.3352588834854848e-14),
    (0x3fb1973bd146606f, -3.765296820388875e-14),
    (0x3fb3bdf5a7d1e06d, 5.1128335719851986e-14),
    (0x3fb5e95a4d97a06b, -5.046674438470119e-14),
    (0x3fb700d30aeac06a, 3.1218748807418837e-15),
    (0x3fb9335e5d594068, 3.3871241029241416e-14),
    (0x3fbb6ac88dad6066, -1.7376727386423858e-14),
    (0x3fbc885801bc4065, 3.957125899799804e-14),
    (0x3fbec739830a2063, -5.2849453521890294e-14),
    (0x3fbfe89139dbe062, -3.767012502308738e-14),
    (0x3fc1178e8227e060, 3.1859736349078334e-14),
    (0x3fc1aa2b7e23f05f, 5.0900642926060466e-14),
    (0x3fc2d1610c86805d, 8.710783796122478e-15),
    (0x3fc365fcb015905c, 6.157896229122976e-16),
    (0x3fc4913d8333b05a, 3.821577743916796e-14),
    (0x3fc527e5e4a1b059, 3.9440046718453496e-14),
    (0x3fc6574ebe8c1057, 2.2924522154618074e-14),
    (0x3fc6f0128b757056, -3.742530094732263e-14),
    (0x3fc7898d85445055, -2.5223102140407338e-14),
    (0x3fc8beafeb390053, -1.0320443688698849e-14),
    (0x3fc95a5adcf70052, 1.0634128304268335e-14),
    (0x3fca93ed3c8ae050, -4.3425422595242564e-14),
    (0x3fcb31d8575bd04f, -1.2527395755711364e-14),
    (0x3fcbd087383be04e, -5.204008743405884e-14),
    (0x3fcc6ffbc6f0104d, -3.979844515951702e-15),
    (0x3fcdb13db0d4904b, -4.7955860343296286e-14),
    (0x3fce530effe7104a, 5.015686013791602e-16),
    (0x3fcef5ade4dd0049, -7.252318953240293e-16),
    (0x3fcf991c6cb3b048, 2.4688324156011588e-14),
    (0x3fd07138604d5846, 5.465121253624792e-15),
    (0x3fd0c42d67616045, 4.102651071698446e-14),
    (0x3fd1178e8227e844, -4.996736502345936e-14),
    (0x3fd16b5ccbacf843, 4.903580708156347e-14),
    (0x3fd1bf99635a6842, 5.089628039500759e-14),
    (0x3fd214456d0eb841, 1.1782016386565151e-14),
    (0x3fd2bef07cdc903f, 4.727452940514406e-14),
    (0x3fd314f1e1d3603e, -4.4204083338755686e-14),
    (0x3fd36b6776be103d, 1.548345993498083e-14),
    (0x3fd3c2527733303c, 2.1522127491642888e-14),
    (0x3fd419b423d5e83b, 1.1054030169005386e-14),
    (0x3fd4718dc271c83a, -5.534326352070679e-14),
    (0x3fd4c9e09e173039, -5.351646604259541e-14),
    (0x3fd522ae0738a038, 5.4612144489920215e-14),
    (0x3fd57bf753c8d037, 2.8136969901227338e-14),
    (0x3fd5d5bddf596036, -1.156568624616423e-14))

 @inline function log_tab_unpack(t::UInt64)
    invc = UInt64(t&UInt64(0xff)|0x1ff00)<<45
    logc = t&(~UInt64(0xff))
    return (reinterpret(Float64, invc), reinterpret(Float64, logc))
end

# Log implementation that returns 2 numbers which sum to give true value with about 68 bits of precision
# Since `log` only makes sense for positive exponents, we speed up the implimentation by stealing the sign bit
# of the input for an extra bit of the exponent which is used to normalize subnormal inputs.
# Does not normalize results.
# Adapted and modified from https://github.com/ARM-software/optimized-routines/blob/master/math/pow.c
# Copyright (c) 2018-2020, Arm Limited. (which is also MIT licensed)
# note that this isn't an exact translation as this version compacts the table to reduce cache pressure.
function _log_ext(xu)
    # x = 2^k z; where z is in range [0x1.69555p-1,0x1.69555p-0) and exact.
    # The range is split into N subintervals.
    # The ith subinterval contains z and c is near the center of the interval.
    tmp = reinterpret(Int64, xu - 0x3fe6955500000000) #0x1.69555p-1
    i = (tmp >> 45) & 127
    z = reinterpret(Float64, xu - (tmp & 0xfff0000000000000))
    k = Float64(tmp >> 52)
    # log(x) = k*Ln2 + log(c) + log1p(z/c-1).
    t, logctail = getfield(t_log_table_compact, UInt8(i+1))
    invc, logc = log_tab_unpack(t)
    # Note: invc is j/N or j/N/2 where j is an integer in [N,2N) and
    # |z/c - 1| < 1/N, so r = z/c - 1 is exactly representible.
    r = fma(z, invc, -1.0)
    # k*Ln2 + log(c) + r.
    t1 = muladd(k, 0.6931471805598903, logc) #ln(2) hi part
    t2 = t1 + r
    lo1 = muladd(k, 5.497923018708371e-14, logctail) #ln(2) lo part
    lo2 = t1 - t2 + r
    ar = -0.5 * r
    ar2, lo3 = two_mul(r, ar)
    # k*Ln2 + log(c) + r + .5*r*r.
    hi = t2 + ar2
    lo4 = t2 - hi + ar2
    p = evalpoly(r, (-0x1.555555555556p-1, 0x1.0000000000006p-1, -0x1.999999959554ep-2, 0x1.555555529a47ap-2, -0x1.2495b9b4845e9p-2, 0x1.0002b8b263fc3p-2))
    lo = lo1 + lo2 + lo3 + muladd(r*ar2, p, lo4)
    return hi, lo
end
