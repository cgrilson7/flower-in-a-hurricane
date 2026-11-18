// @title Flower in a hurricane
// @spawn 0 2 -9 0
// @speed 2
// A music video, cut to the song: T is the song's second (iTime + T0). 126 BPM, beats on multiples of 0.4762 s.
// Rendered offline (render.sh): the scene is far too heavy to fly live. flower.v1.glsl is the light first version.
#define T0 0.0
#define FAR 260.0
#define SUN normalize(vec3(-0.35, 0.55, -0.75))

const float BEAT = 0.476190, BAR = 1.904762;
const vec3 PM = vec3(-2.3, 0.0, 0.3), PF = vec3(2.3, 0.0, 0.3), PA = vec3(-0.72, 0.0, 3.25), PB = vec3(0.72, 0.0, 3.25);
const vec3 FB = vec3(0.0, 0.0, -2.0);
const float GA = 0.42, UA = 0.27, FA = 0.25;      // the guitar's tilt; upper arm and forearm lengths

float T = 0.0, pul = 0.0, gFog = 0.012, crossI = 0.0, beamI = 0.0, lit = 0.0, rain = 1.0, wave = 1.0, wind = 1.0;
float veins = 0.0, bloom = 0.0, fsc = 1.0, dawn = 0.0, fade = 1.0, whiteout = 0.0, spotI = 0.0, ring = 1e3, boltA = 0.0, drop = 0.0;
vec3 gSun = vec3(0.08, 0.09, 0.14), beamC = vec3(1.0), gCam = vec3(0.0, 2.0, -9.0), gTint = vec3(1.0);
// what the last scene() call hit: material id, a point local to that part, and whose body it is
float gid = 0.0, gw = 0.0, cw = 0.0;
vec3 gq = vec3(0.0), lq = vec3(0.0);
bool gDet = false, gDetH = false;
vec4 gLod = vec4(0.0);        // camera distance to the guitarist, the singer, DJ A, DJ B

// a posed body: shoulders, elbows, wrists, hand frames (fingers along hf, back of the hand hn), knees, ankles
struct Rig { vec3 sR, sL, eR, eL, wR, wL, hfR, hnR, hfL, hnL, kR, kL, aR, aL; float cR, cL, nod, turn, lean, bob, mo; };
Rig RM, RF, RA, RB;
vec3 micA = vec3(0.0), micB = vec3(0.0, 1.5, -0.14), GO = vec3(0.03, 0.99, -0.165);

float ease(float a, float b, float x){ return smoothstep(a, b, x); }
float hit(float t, float at, float amp, float k){ return t < at ? 0.0 : amp*exp(-(t - at)*k); }
float sdEll(vec3 p, vec3 r){ float k0 = length(p/r), k1 = length(p/(r*r)); return k0*(k0 - 1.0)/k1; }
float sdRC(vec3 p, vec3 a, vec3 b, float r1, float r2){
  vec3 ba = b - a, pa = p - a;
  float l2 = dot(ba, ba), rr = r1 - r2, a2 = l2 - rr*rr, il2 = 1.0/l2;
  float y = dot(pa, ba), z = y - l2;
  vec3 xx = pa*l2 - ba*y;
  float x2 = dot(xx, xx), y2 = y*y*l2, z2 = z*z*l2, k = sign(rr)*rr*rr*x2;
  if (sign(z)*a2*z2 > k) return sqrt(x2 + z2)*il2 - r2;
  if (sign(y)*a2*y2 < k) return sqrt(x2 + y2)*il2 - r1;
  return (sqrt(x2*a2*il2) + y*rr)*il2 - r1;
}
void U(inout float d, float k, float id){ if (k < d){ d = k; gid = id; gq = lq; gw = cw; } }
// a tapered limb; when it wins, gq is (angle around the bone, 0..1 along it, radius there): stripes that follow the cloth
void UB(inout float d, vec3 q, vec3 a, vec3 b, float r1, float r2, float id){
  float k = sdRC(q, a, b, r1, r2);
  if (k < d){
    d = k; gid = id; gw = cw;
    vec3 ba = b - a; float l = length(ba); ba /= l;
    vec3 e1 = normalize(cross(ba, vec3(0.5, 0.1, 0.85))), e2 = cross(ba, e1), v = q - a;
    float h = clamp(dot(v, ba)/l, 0.0, 1.0);
    gq = vec3(atan(dot(v, e1), dot(v, e2)), h, mix(r1, r2, h));
  }
}
vec3 ik(vec3 a, vec3 c, float l1, float l2, vec3 pole){
  vec3 ac = c - a; float dl = length(ac), dd = min(dl, l1 + l2 - 0.002);
  vec3 dir = ac/dl;
  float x = (l1*l1 - l2*l2 + dd*dd)/(2.0*dd), h = sqrt(max(l1*l1 - x*x, 0.0));
  return a + dir*x + normalize(pole - dir*dot(pole, dir))*h;
}
vec3 orth(vec3 n, vec3 f){ return normalize(n - f*dot(n, f)); }
vec3 leanP(vec3 r, float lean, float bob){ r.y -= 0.95; r.yz = rot(-lean)*r.yz; r.y += 0.95 + bob; return r; }
vec3 gpt(vec3 g){ return GO + vec3(rot(GA)*g.xy, g.z); }

// ---------------------------------------------------------------- the bodies

// a hand at wrist w: fingers along f, back of the hand n, curl 0 (flat) to 1.3 (fist), thumb on the -x*side edge
float hand(vec3 q, vec3 w, vec3 f, vec3 n, float c, float side){
  vec3 v = q - w, s = cross(n, f);
  vec3 h = vec3(dot(v, s), dot(v, n), dot(v, f));
  float bd = length(h - vec3(0.0, -0.01, 0.07)) - 0.13;
  if (bd > 0.05) return bd;
  if (!gDetH) return sdEll(h - vec3(0.0, -0.008*c, 0.07), vec3(0.042, 0.022 + 0.012*c, 0.075 - 0.02*c));
  float d = sdEll(h - vec3(0.0, 0.0, 0.05), vec3(0.042, 0.018, 0.052));
  for (int i = 0; i < 4; i++){
    float fi = float(i), L = 0.034 - 0.005*abs(fi - 1.3), c1 = c*(0.82 + 0.06*fi);
    vec3 b = vec3(-0.031 + 0.0205*fi, 0.0, 0.09 - 0.005*abs(fi - 1.3));
    vec3 m = b + L*vec3(0.0, -sin(c1), cos(c1));
    vec3 t = m + L*0.8*vec3(0.0, -sin(2.0*c1), cos(2.0*c1));
    vec3 e = t + L*0.62*vec3(0.0, -sin(2.7*c1), cos(2.7*c1));
    float k = min(min(sdCapsule(h, b, m, 0.0098), sdCapsule(h, m, t, 0.0088)), sdCapsule(h, t, e, 0.008));
    d = smin(d, k, 0.007);
  }
  vec3 tb = vec3(-0.03*side, -0.006, 0.018), tm = tb + vec3(-0.03*side, -0.012 - 0.012*c, 0.03);
  vec3 tt = tm + vec3((-0.006 + 0.022*c)*side, -0.016*c, 0.034);
  return smin(d, min(sdCapsule(h, tb, tm, 0.0125), sdCapsule(h, tm, tt, 0.0098)), 0.01);
}

// the head, in its own space (centre of the skull at 0, face toward -z); mo opens the mouth; fem softens it
void head(inout float d, vec3 h, float mo, float fem){
  vec3 m = vec3(abs(h.x), h.yz);
  float k = sdEll(h - vec3(0.0, 0.022, 0.012), vec3(0.092, 0.108, 0.108));
  k = smin(k, sdEll(h - vec3(0.0, -0.046 - 0.01*mo, -0.028), vec3(0.069 - 0.005*fem, 0.07, 0.074)), 0.04);
  if (gDet){
    k = smin(k, sdSphere(m - vec3(0.046, -0.018, -0.07), 0.031), 0.03);                                     // cheekbones
    k = smin(k, sdCapsule(m, vec3(0.0, 0.04, -0.09), vec3(0.052, 0.04, -0.078), 0.013 - 0.004*fem), 0.02);    // brow
    k = smax(k, -sdSphere(m - vec3(0.037, 0.014, -0.106), 0.021), 0.012);                                   // sockets
    k = smin(k, sdRC(h, vec3(0.0, 0.03, -0.097), vec3(0.0, -0.02, -0.121 + 0.004*fem), 0.009, 0.0135), 0.012);  // nose
    k = smin(k, sdSphere(m - vec3(0.012 + 0.003*fem, -0.023, -0.107), 0.008), 0.01);
    k = smin(k, sdSphere(h - vec3(0.0, -0.092 - 0.014*mo, -0.082), 0.024 - 0.004*fem), 0.03);               // chin
    k = smax(k, -sdEll(h - vec3(0.0, -0.059 - 0.007*mo, -0.106), vec3(0.021, 0.0025 + 0.013*mo, 0.022)), 0.004);
    k = smin(k, sdEll(m - vec3(0.092, -0.002, 0.012), vec3(0.009, 0.029, 0.018)), 0.008);                   // ears
  }
  lq = h; U(d, k, 10.0);
  if (gDet){
    vec3 ec = vec3(0.0365, 0.015, -0.0885);
    lq = m - ec; U(d, sdSphere(m - ec, 0.0145), 16.0);
    float bl = step(0.96, fract(T*0.31 + cw*0.37))*0.012;                                                   // a blink
    float lid = max(sdSphere(m - ec, 0.0168), 0.0012 - bl - (m.y - ec.y) + 0.12*(m.x - ec.x));
    lid = min(lid, max(sdSphere(m - ec, 0.0162), (m.y - ec.y) + 0.0085));
    lq = h; U(d, lid, 10.0);
    k = sdEll(h - vec3(0.0, -0.0515, -0.1045), vec3(0.021 + 0.003*fem, 0.0055 + 0.002*fem, 0.011));
    k = min(k, sdEll(h - vec3(0.0, -0.0665 - 0.014*mo, -0.1015), vec3(0.018 + 0.003*fem, 0.0065 + 0.003*fem, 0.011)));
    U(d, k, 17.0);
    U(d, sdCapsule(m, vec3(0.014, 0.044 + 0.002*fem, -0.1035), vec3(0.055, 0.047 + 0.004*fem, -0.085), 0.0036 - 0.0008*fem), 18.0);
  }
}

float gyr(vec3 g){ return dot(sin(g), cos(g.zxy)); }

// long straight hair past the shoulders, centre part (h: head space, s: torso space)
void hairM(inout float d, vec3 h, vec3 s){
  float fall = ease(1.62, 1.2, s.y);
  s.x += wind*0.022*sin(T*2.3 + s.y*4.0)*fall;
  vec3 m = vec3(abs(s.x), s.yz);
  // a soft wave that grows toward the tips
  m.x += 0.009*sin(s.y*21.0 + 1.3*sign(s.x))*fall; m.z += 0.007*sin(s.y*17.0 + 2.0)*fall;
  float k = sdEll(h - vec3(0.0, 0.034, 0.022), vec3(0.101, 0.11, 0.116));
  float c = sdRC(m, vec3(0.084, 1.66, -0.02), vec3(0.118, 1.27, -0.05), 0.041, 0.016);
  c = min(c, sdRC(m, vec3(0.055, 1.62, 0.07), vec3(0.075, 1.22, 0.078), 0.058, 0.022));
  k = smin(k, c, 0.03);
  k = smax(k, -sdEll(h - vec3(0.0, -0.03, -0.13), vec3(0.069, 0.152, 0.1)), 0.018);
  k = max(k, 0.0035 - abs(h.x) - 0.3*(1.0 - ease(0.05, 0.1, h.y)*step(h.z, 0.03)));           // the centre part
  float st = atan(m.x, 0.25 - h.z)*260.0 + 5.0*sin(s.y*19.0 + 6.0*m.x);
  if (gDet) k += 0.0007*sin(st) + 0.0005*sin(st*0.37 + 2.0);
  lq = vec3(st, s.y, h.y); U(d, k*0.85, 11.0);
}

// very big curly hair to mid-back: clumps of curls, lumps of noise on a wide envelope
void hairF(inout float d, vec3 h, vec3 s){
  s.x += wind*0.03*sin(T*2.7 + s.y*3.0)*ease(1.75, 1.1, s.y);
  vec3 m = vec3(abs(s.x), s.yz);
  float e = sdEll(s - vec3(0.0, 1.665, 0.05), vec3(0.185, 0.18, 0.19));
  e = smin(e, sdEll(s - vec3(0.0, 1.36, 0.125), vec3(0.3, 0.38, 0.16)), 0.1);
  e = smin(e, sdEll(m - vec3(0.2, 1.4, -0.02), vec3(0.085, 0.3, 0.095)), 0.08);
  e = smax(e, -sdEll(h - vec3(0.0, -0.035, -0.17), vec3(0.073, 0.128, 0.15)), 0.03);
  float k = e;
  vec3 g = s*vec3(46.0, 34.0, 46.0) + 1.5*sin(s.yzx*13.0);
  float gy = noise(g) + 0.5*noise(g*2.3 + 5.0) + 0.25*noise(g*5.1);
  if (gDet) k = e - 0.036*(gy - 0.85);
  lq = vec3(gy, s.y, e); U(d, k*0.75, 12.0);
}

// a DJ's hair: w 0 a big dark curly mop and a full beard, w 1 short dark hair
void hairDJ(inout float d, vec3 h, float w){
  float k;
  if (w < 0.5){
    float e = sdEll(h - vec3(0.0, 0.065, 0.02), vec3(0.15, 0.135, 0.15));
    e = smax(e, -sdEll(h - vec3(0.0, -0.05, -0.15), vec3(0.075, 0.125, 0.13)), 0.03);
    float gy = noise(h*75.0) + 0.5*noise(h*160.0 + 7.0);
    k = gDet ? e - 0.022*(gy - 0.75) : e;
    lq = vec3(gy, h.y, e); U(d, k*0.75, 13.0);
    k = sdEll(h - vec3(0.0, -0.075, -0.035), vec3(0.073, 0.062, 0.078));
    k = max(k, h.y + 0.028 - 0.5*max(abs(h.x) - 0.045, 0.0));
    k = min(k, sdCapsule(vec3(abs(h.x), h.yz), vec3(0.0, -0.042, -0.112), vec3(0.027, -0.05, -0.1), 0.0075));
    k = max(k, -sdEll(h - vec3(0.0, -0.062, -0.11), vec3(0.016, 0.006, 0.02)));
    if (gDet) k += 0.004*noise(h*260.0) - 0.002;
    lq = h; U(d, k*0.8, 15.0);
  } else {
    k = sdEll(h - vec3(0.0, 0.04, 0.02), vec3(0.106, 0.112, 0.12));
    k = smin(k, sdEll(h - vec3(0.0, 0.085, -0.075), vec3(0.085, 0.035, 0.05)), 0.03);         // a fringe
    k = smax(k, -sdEll(h - vec3(0.0, -0.06, -0.13), vec3(0.074, 0.115, 0.1)), 0.02);
    float st = atan(h.x, h.z)*70.0 + 3.0*sin(h.y*40.0);
    if (gDet) k += 0.002*sin(st);
    lq = vec3(st, h.y, 0.0); U(d, k*0.85, 14.0);
  }
}

// the short full beard of the guitarist
void beardM(inout float d, vec3 h, float mo){
  float k = sdEll(h - vec3(0.0, -0.062 - 0.008*mo, -0.03), vec3(0.073, 0.063, 0.079));
  k = max(k, h.y + 0.03 - 0.6*max(abs(h.x) - 0.04, 0.0));
  k = min(k, sdCapsule(vec3(abs(h.x), h.yz), vec3(0.0, -0.043, -0.112), vec3(0.026, -0.05, -0.101), 0.007));
  k = max(k, -sdEll(h - vec3(0.0, -0.061 - 0.007*mo, -0.11), vec3(0.018, 0.007 + 0.012*mo, 0.022)));
  if (gDet) k += 0.003*noise(h*280.0) - 0.0015;
  lq = h; U(d, k*0.8, 15.0);
}

// the cream guitar, in its own space: x along the neck, the top toward -z
void guitar(inout float d, vec3 g){
  float b = smin(length(g.xy - vec2(-0.135, -0.005)) - 0.162, length(g.xy - vec2(0.065, 0.012)) - 0.122, 0.07);
  b = smax(b, -(length(g.xy - vec2(0.215, -0.13)) - 0.08), 0.03);
  b = smax(b, -(length(g.xy - vec2(0.2, 0.15)) - 0.062), 0.03);
  b = smax(b, -(length(g.xy - vec2(-0.02, 0.215)) - 0.075), 0.04);
  lq = g;
  U(d, max(b, abs(g.z) - 0.016) - 0.008, 25.0);
  float k = sdBox(g - vec3(0.42, 0.0, -0.012), vec3(0.25, 0.0225, 0.01)) - 0.004;
  vec3 hs = g - vec3(0.745, 0.014, -0.004);
  hs.xy = rot(0.1)*hs.xy;
  k = min(k, sdBox(hs, vec3(0.08, 0.034 - 0.1*hs.x*0.6, 0.007)) - 0.005);
  U(d, k, 26.0);
  float tx = g.x - 0.69; tx -= 0.026*clamp(floor(tx/0.026 + 0.5), 0.0, 5.0);
  k = min(sdSphere(vec3(tx, g.y - 0.06, g.z + 0.002), 0.0085), sdCapsule(vec3(tx, g.y - 0.035, g.z + 0.02), vec3(0.0), vec3(0.0, 0.0, -0.01), 0.004));
  k = min(k, sdBox(g - vec3(-0.205, 0.0, -0.028), vec3(0.011, 0.04, 0.005)) - 0.002);                    // bridge
  vec2 kn = vec2(g.x + 0.19 - 0.055*step(-0.165, g.x), g.y + 0.092 + 0.02*step(-0.165, g.x));
  k = min(k, max(length(kn) - 0.012, abs(g.z + 0.03) - 0.007));                                          // knobs
  U(d, k, 28.0);
  float px = g.x + 0.115 - 0.135*step(-0.05, g.x);
  U(d, sdBox(vec3(px, g.y, g.z + 0.027), vec3(0.014, 0.04, 0.0035)) - 0.002, 27.0);                      // pickups
}

// the shared body. who: 0 the guitarist, 1 the singer, 2 DJ A, 3 DJ B
void human(inout float d, vec3 q, Rig r, float who){
  float k;
  bool F = who > 0.5 && who < 1.5, M = who < 0.5, DJ = who > 1.5;
  vec3 t = q; t.y -= 0.95; t.yz = rot(r.lean)*t.yz; t.y += 0.95 - r.bob;       // torso space
  vec3 hpR = vec3(-0.09, 0.93 + r.bob, 0.0), hpL = vec3(0.09, 0.93 + r.bob, 0.0);
  // legs and shoes
  if (F){
    UB(d, q, hpR + vec3(-0.02, 0.0, 0.0), r.kR, 0.125, 0.115, 44.0); UB(d, q, r.kR, r.aR + vec3(0.0, -0.02, 0.0), 0.115, 0.125, 45.0);
    UB(d, q, hpL + vec3(0.02, 0.0, 0.0), r.kL, 0.125, 0.115, 46.0); UB(d, q, r.kL, r.aL + vec3(0.0, -0.02, 0.0), 0.115, 0.125, 47.0);
  } else {
    float id = M ? 21.0 : 48.0;
    lq = q;
    k = min(min(sdRC(q, hpR, r.kR, 0.082, 0.058), sdRC(q, r.kR, r.aR, 0.058, 0.046)), min(sdRC(q, hpL, r.kL, 0.082, 0.058), sdRC(q, r.kL, r.aL, 0.058, 0.046)));
    U(d, k, id);
  }
  vec3 sq = vec3(q.x - (q.x < 0.0 ? r.aR.x : r.aL.x), q.y, q.z - (q.x < 0.0 ? r.aR.z : r.aL.z));
  k = max(sdEll(sq - vec3(0.0, 0.035, -0.055), vec3(0.052, 0.055, 0.135)), -q.y);
  lq = sq; U(d, k, 19.0);
  // torso
  if (M){
    k = smin(sdEll(t - vec3(0.0, 1.27, 0.0), vec3(0.175, 0.2, 0.115)), sdEll(t - vec3(0.0, 1.05, 0.0), vec3(0.155, 0.19, 0.11)), 0.08);
    k = smin(k, sdCapsule(t, vec3(-0.16, 1.4, 0.0), vec3(0.16, 1.4, 0.0), 0.058), 0.05);
    k = max(k, 0.89 - t.y);
    if (gDet) k += 0.004*sin(t.y*31.0 + 5.0*t.x + 2.0*sin(t.x*17.0))*ease(1.35, 1.1, t.y) + 0.003*sin(t.x*44.0 + t.y*9.0)*ease(1.2, 0.95, t.y);
    lq = t; U(d, k*0.9, 20.0);
    U(d, sdEll(t - vec3(0.0, 0.95, 0.0), vec3(0.15, 0.13, 0.1)), 21.0);
  } else if (F){
    k = sdBox(t - vec3(0.0, 1.17, 0.0), vec3(0.17, 0.22, 0.06)) - 0.07;
    k = smin(k, sdCapsule(t, vec3(-0.22, 1.4, 0.0), vec3(0.22, 1.4, 0.0), 0.068), 0.05);
    k = smin(k, sdTorus(vec3(t.x, t.y - 0.9, t.z*1.5), vec2(0.195, 0.032)), 0.02);                      // the waistband
    float v = 0.014 + 0.4*max(t.y - 1.12, 0.0);                                                         // the open front
    k = max(k, -max(max(abs(t.x) - v, -t.z - 0.3), t.z));
    if (gDet) k += 0.004*sin(t.y*24.0 + 6.0*abs(t.x) + 2.0*sin(t.x*13.0));
    lq = t; U(d, k*0.9, 22.0);
    U(d, sdEll(t - vec3(0.0, 1.17, 0.0), vec3(0.15, 0.3, 0.115)), 29.0);                                 // her top
    vec3 c = vec3(abs(t.x) - 0.085, t.y - 1.425, t.z + 0.11);                                           // collar points
    c.xy = rot(-0.75)*c.xy; c.xz = rot(0.5)*c.xz;
    U(d, sdBox(c, vec3(0.05, 0.022, 0.003)) - 0.006, 22.0);
    U(d, sdEll(t - vec3(0.0, 0.93, 0.0), vec3(0.2, 0.15, 0.14)), 44.0);
  } else {
    k = smin(sdEll(t - vec3(0.0, 1.26, 0.0), vec3(0.19, 0.21, 0.125)), sdEll(t - vec3(0.0, 1.04, 0.0), vec3(0.17, 0.2, 0.125)), 0.08);
    k = smin(k, sdCapsule(t, vec3(-0.17, 1.39, 0.0), vec3(0.17, 1.39, 0.0), 0.065), 0.05);
    k = smin(k, sdTorus(t - vec3(0.0, 1.455, 0.0), vec2(0.06, 0.022)), 0.015);                          // collar
    k = max(k, 0.87 - t.y);
    if (gDet) k += 0.004*sin(t.y*26.0 + 5.0*t.x + 2.0*sin(t.x*15.0));
    lq = t; U(d, k*0.9, who < 2.5 ? 23.0 : 24.0);
    U(d, sdEll(t - vec3(0.0, 0.93, 0.0), vec3(0.16, 0.14, 0.11)), 48.0);
  }
  // neck, head, hair
  lq = t; U(d, sdRC(t, vec3(0.0, 1.41, 0.005), vec3(0.0, 1.54, -0.008), 0.05 - 0.006*float(F), 0.045 - 0.006*float(F)), 10.0);
  vec3 h = t - vec3(0.0, 1.5, 0.0);
  h.yz = rot(r.nod)*h.yz; h.xz = rot(r.turn)*h.xz;
  h -= vec3(0.0, 0.128, -0.012);
  head(d, h, r.mo, float(F));
  if (M){ hairM(d, h, t); beardM(d, h, r.mo); }
  else if (F) hairF(d, h, t);
  else hairDJ(d, h, who - 2.0);
  // arms
  if (M){
    lq = q;
    k = min(min(sdRC(q, r.sR, r.eR, 0.048, 0.04), sdRC(q, r.eR, r.wR, 0.04, 0.029)), min(sdRC(q, r.sL, r.eL, 0.048, 0.04), sdRC(q, r.eL, r.wL, 0.04, 0.029)));
    U(d, k, 10.0);
    k = min(sdRC(q, r.sR, mix(r.sR, r.eR, 0.5), 0.06, 0.054), sdRC(q, r.sL, mix(r.sL, r.eL, 0.5), 0.06, 0.054));
    lq = t; U(d, k, 20.0);
  } else if (F){
    UB(d, q, r.sR + vec3(-0.02, 0.0, 0.0), r.eR, 0.08, 0.07, 40.0); UB(d, q, r.eR, mix(r.eR, r.wR, 0.8), 0.07, 0.048, 41.0);
    UB(d, q, r.sL + vec3(0.02, 0.0, 0.0), r.eL, 0.08, 0.07, 42.0); UB(d, q, r.eL, mix(r.eL, r.wL, 0.8), 0.07, 0.048, 43.0);
    k = min(sdCapsule(q, mix(r.eR, r.wR, 0.76), mix(r.eR, r.wR, 0.8), 0.053), sdCapsule(q, mix(r.eL, r.wL, 0.76), mix(r.eL, r.wL, 0.8), 0.053));
    lq = vec3(0.0, 0.5, 0.08); U(d, k, 41.0);                                                           // rolled cuffs
    lq = q; U(d, min(sdRC(q, r.eR, r.wR, 0.035, 0.026), sdRC(q, r.eL, r.wL, 0.035, 0.026)), 10.0);
  } else {
    float id = who < 2.5 ? 23.0 : 24.0;
    UB(d, q, r.sR, r.eR, 0.068, 0.058, id + 26.0); UB(d, q, r.eR, mix(r.eR, r.wR, 0.9), 0.058, 0.046, id + 28.0);
    UB(d, q, r.sL, r.eL, 0.068, 0.058, id + 26.0); UB(d, q, r.eL, mix(r.eL, r.wL, 0.9), 0.058, 0.046, id + 28.0);
    lq = q; U(d, min(sdRC(q, r.eR, r.wR, 0.035, 0.028), sdRC(q, r.eL, r.wL, 0.035, 0.028)), 10.0);
  }
  lq = q;
  U(d, hand(q, r.wR, r.hfR, r.hnR, r.cR, M ? -1.0 : 1.0), 10.0);
  U(d, hand(q, r.wL, r.hfL, r.hnL, r.cL, M ? -1.0 : -1.0), 10.0);
}

void male(inout float d, vec3 q){
  cw = 0.0;
  human(d, q, RM, 0.0);
  vec3 g = q - GO; g.xy = rot(-GA)*g.xy;
  guitar(d, g);
  lq = q;
  vec3 sp = RM.sL + vec3(-0.04, 0.068, -0.02);
  U(d, min(sdCapsule(q, gpt(vec3(0.17, 0.1, 0.012)), sp, 0.012), sdCapsule(q, sp, sp + vec3(-0.03, -0.12, 0.13), 0.012)), 27.0);         // the strap
  // the mic stand
  float k = min(sdCapsule(q, vec3(0.0, 0.0, -0.52), vec3(0.0, 1.3, -0.52), 0.013), sdCapsule(q, vec3(0.0, 1.3, -0.52), vec3(0.0, 1.445, -0.265), 0.01));
  k = min(k, sdRC(q, vec3(0.0, 1.445, -0.275), vec3(0.0, 1.487, -0.21), 0.016, 0.02));
  k = min(k, sdCylinder(q - vec3(0.0, 0.012, -0.52), 0.17, 0.012));
  U(d, k, 27.0);
  U(d, sdSphere(q - vec3(0.0, 1.502, -0.187), 0.029), 33.0);
}

void female(inout float d, vec3 q){
  cw = 1.0;
  human(d, q, RF, 1.0);
  vec3 m = normalize(micB - micA);
  lq = q;
  U(d, sdRC(q, micA, micB - m*0.04, 0.015, 0.02), 27.0);
  U(d, sdSphere(q - micB, 0.03), 33.0);
  if (gDetH) U(d, sdCapsule(q, micB - m*0.036, micB - m*0.03, 0.0225), 28.0);
}

void dj(inout float d, vec3 q, float w){
  cw = 2.0 + w;
  if (w < 0.5) human(d, q, RA, 2.0); else human(d, q, RB, 3.0);
}

// the flower, base at the origin; it blooms with `bloom` and grows with `fsc`
void flower(inout float d0, vec3 q){
  float d = 1e3, id0 = gid, w0 = gw; vec3 q0 = gq;
  cw = 9.0;
  q /= fsc;
  q.x -= (0.12*wind + 0.06*wind*sin(T*3.1))*q.y*q.y;
  const float H = 1.25;
  lq = q;
  U(d, sdRC(q, vec3(0.0), vec3(0.0, H, 0.0), 0.026, 0.017), 32.0);
  vec3 l = vec3(abs(q.x) - 0.14, q.y - 0.45 - 0.15*step(0.0, q.x), q.z);
  l.xy = rot(0.5)*l.xy; l.yz = rot(0.7)*l.yz;
  l.y -= 0.6*l.x*l.x + 1.5*l.z*l.z;
  lq = l; U(d, sdEll(l, vec3(0.16, 0.012, 0.07))*0.7, 34.0);
  vec3 c = q - vec3(0.0, H, 0.0);
  c.yz = rot(-0.7)*c.yz;
  lq = c; U(d, sdEll(c + vec3(0.0, 0.0, 0.02), vec3(0.07 + 0.03*bloom, 0.07 + 0.03*bloom, 0.045)) + 0.004*sin(atan(c.y, c.x)*21.0 + length(c.xy)*160.0)*0.5, 31.0);
  for (int j = 0; j < 2; j++){
    float fj = float(j), sec = 6.2832/7.0;
    float a = atan(c.y, c.x) + fj*sec*0.5, r = length(c.xy);
    float i = floor(a/sec + 0.5), aa = a - i*sec;
    vec2 pl = vec2(cos(aa), sin(aa))*r;
    float L = (0.1 + 0.2*bloom)*(1.0 - 0.12*fj);
    float z = c.z - 0.012*fj + (1.0 - bloom)*pl.x*(1.4 - 0.2*fj) - 0.25*bloom*pl.x*pl.x*(1.0 + fj) + 0.03*wind*sin(T*9.0 + i*1.7 + fj)*pl.x - 1.6*pl.y*pl.y;
    vec3 pp = vec3(pl.x - 0.05 - L, pl.y, z);
    lq = vec3(pp.x/L, pp.y/(0.07 + 0.05*bloom), fj);
    U(d, sdEll(pp, vec3(L, 0.07 + 0.05*bloom, 0.012))*0.5, 30.0);
  }
  if (d*fsc < d0) d0 = d*fsc; else { gid = id0; gw = w0; gq = q0; }
}

// ---------------------------------------------------------------- the island, the sea, the stage

float seaH(vec2 x){
  float r = length(x - vec2(0.0, 0.5));
  float h = 0.55*sin(x.x*0.19 + T*1.25 + 0.6*sin(x.y*0.11)) + 0.4*sin(x.y*0.16 - T*1.05 + x.x*0.09);
  float c1 = 1.0 - abs(sin(dot(x, vec2(0.33, 0.21)) + T*1.7 + 3.0*noise(x*0.11)));
  float c2 = 1.0 - abs(sin(dot(x, vec2(-0.27, 0.46)) + T*2.1 + 2.0*noise(x*0.17 + 9.0)));
  h += 0.55*c1*c1 + 0.3*c2*c2 - 0.3;
  h += 0.3*noise(x*0.6 + T*vec2(0.9, 0.3)) + 0.1*noise(x*1.9 + T*vec2(1.6, 0.7));
  h *= wave;
  float k = r - ring, A = 3.2 + 3.3*ease(45.0, 9.0, ring);
  h += A*exp(-k*k*(k < 0.0 ? 0.05 : 0.012));                    // the wave that washes it all away
  return h - 4.0;
}

float rockBase(vec3 p){
  vec3 q = p - vec3(0.0, 0.0, 0.5);
  float a = atan(q.z, q.x), r = length(q.xz);
  float R = 8.1 + 0.6*sin(a*3.0 + 0.7) + 0.35*sin(a*5.0 + 2.0);
  float d = (r - R - max(-q.y, 0.0)*0.5)*0.88;
  d = smax(d, q.y, 0.3);
  d = smin(d, sdRC(p, vec3(-5.2, -2.5, 7.8), vec3(-6.0, 4.8, 8.8), 2.6, 0.5), 0.8);
  d = smin(d, sdRC(p, vec3(3.8, -2.5, 8.8), vec3(4.6, 3.0, 9.6), 2.3, 0.4), 0.8);
  d = smin(d, sdRC(p, vec3(9.5, -3.0, 3.0), vec3(10.4, 2.2, 3.6), 2.0, 0.35), 0.8);
  d = smin(d, sdRC(p, vec3(-8.2, -3.0, -6.2), vec3(-9.0, 0.6, -7.0), 1.8, 0.35), 0.8);
  return d;
}
float rock(vec3 p){
  float d = rockBase(p);
  if (d > 1.8) return d - 1.2;
  float w = ease(0.03, 0.5, abs(p.y))*(p.y > 0.0 ? ease(6.4, 7.6, length(p.xz - vec2(0.0, 0.5))) : 1.0);
  float f = fbm(p*0.45);
  float disp = 1.5*(f - 0.5) + 0.22*ease(0.25, 0.75, fract(p.y*0.55 + 1.2*f));
  disp += 0.15*(1.0 - ease(0.0, 0.1, abs(2.0*noise(p*1.7 + 5.0) - 1.0))) + 0.05*noise(p*6.0) + 0.5*abs(2.0*noise(p*0.8 + 2.0) - 1.0) - 0.25;
  return (d + w*disp)*0.6;
}
// boulders standing in the sea around the island
float stacks(vec3 p){
  vec2 c = floor(p.xz/11.0), l = p.xz - (c + 0.5)*11.0;
  float r = length((c + 0.5)*11.0 - vec2(0.0, 0.5));
  float edge = 6.7 - max(abs(l.x), abs(l.y));
  if (p.y > 1.0 || hash(c + 3.7) < 0.8 || r < 20.0 || r > 80.0) return max(edge, p.y - 0.5);
  vec2 o = (vec2(hash(c + 1.3), hash(c + 9.1)) - 0.5)*5.0;
  float H = 1.0 + 2.4*hash(c + 5.5);
  vec3 q = vec3(l.x - o.x, p.y + 4.5, l.y - o.y);
  float d = sdEll(q, vec3(1.0 + H*0.3, H + 0.5, 0.9 + H*0.25)) + 1.5*fbm(p*0.55) - 0.75 + 0.12*noise(p*4.0);
  return min(d*0.45, edge);
}

float scene(vec3 p){
  gid = 0.0; gw = 9.0; cw = 9.0; lq = p; gq = p;
  float sh = p.y + 4.0, hm = 2.6*wave + (ring < 200.0 ? 7.0 : 0.0);
  float d = sh > hm + 1.5 ? sh - hm : (p.y - seaH(p.xz))*0.42, k;
  U(d, min(rock(p), stacks(p)), 1.0);
  U(d, sdBox(p - vec3(0.0, 0.02, 3.0), vec3(2.5, 0.04, 1.15)) - 0.01, 7.0);
  // the cross: seven metres of it, behind the booth
  U(d, min(sdBox(p - vec3(0.0, 3.6, 7.0), vec3(0.75, 3.6, 0.2)), sdBox(p - vec3(0.0, 4.7, 7.0), vec3(2.4, 0.75, 0.2))) - 0.03, 5.0);
  // four lighting towers, a lamp on each
  vec3 tq = vec3(abs(p.x) - 6.0, p.y, abs(p.z - 0.5) - 4.0);
  k = length(tq.xz) - 0.45;
  if (k < 0.3 && p.y < 7.0){
    vec2 c = abs(tq.xz) - 0.13;
    float f = abs(mod(p.y, 0.5) - 0.25);
    k = max(length(c) - 0.02, p.y - 6.0);
    k = min(k, max(max(abs(max(abs(tq.x), abs(tq.z)) - 0.13) - 0.012, f - 0.238 + 0.226), p.y - 6.0)*0.0 + max(length(vec2(max(abs(tq.x), abs(tq.z)) - 0.13, f - 0.25)) - 0.014, p.y - 6.0));
    k = min(k, max(min(length(vec2(abs(tq.x) - 0.13, (abs(tq.z) - f*1.04)*0.7)), length(vec2(abs(tq.z) - 0.13, (abs(tq.x) - f*1.04)*0.7))) - 0.01, p.y - 6.0));
    k = max(k, max(abs(tq.x), abs(tq.z)) - 0.16);
    k = min(k, sdBox(tq - vec3(0.0, 6.02, 0.0), vec3(0.17, 0.03, 0.17)));
    U(d, k, 3.0);
    lq = tq; U(d, sdRC(tq, vec3(0.0, 6.28, 0.0), vec3(-0.2, 6.14, -0.13), 0.15, 0.17), 8.0);
    lq = p;
  } else U(d, max(k, p.y - 6.6), 3.0);
  // the booth: road cases, the decks and the synth, and the cross on its front
  k = length(p - vec3(0.0, 0.8, 2.6)) - 2.5;
  if (k < 0.1){
    U(d, sdBox(p - vec3(0.0, 0.5, 2.65), vec3(1.9, 0.5, 0.42)), 4.0);
    // DJ A's side: two decks and a mixer
    vec3 a = p - vec3(-0.78, 1.045, 2.72);
    float dx = abs(a.x) - 0.47;
    k = min(sdBox(vec3(dx, a.y, a.z), vec3(0.2, 0.04, 0.2)) - 0.005, sdBox(a, vec3(0.15, 0.05, 0.2)) - 0.005);
    k = min(k, sdCylinder(vec3(dx, a.y - 0.052, a.z), 0.145, 0.008));
    if (gDetH){
      vec2 kb = vec2(mod(a.x + 0.125, 0.05) - 0.025, mod(a.z + 0.02, 0.06) - 0.03);
      k = min(k, max(max(length(kb) - 0.011, abs(a.y - 0.065) - 0.012), max(abs(a.x) - 0.125, abs(a.z + 0.02) - 0.15)));
    }
    lq = a; U(d, k, 6.0);
    // DJ B's side: a synth on a stand
    vec3 s = p - vec3(0.8, 1.11, 2.74);
    k = sdBox(s + vec3(0.0, 0.07, 0.0), vec3(0.5, 0.04, 0.2));
    s.yz = rot(0.16)*s.yz;
    k = min(k, sdBox(s, vec3(0.56, 0.035, 0.19)) - 0.006);
    if (gDetH){
      vec2 kb = vec2(mod(s.x, 0.07) - 0.035, mod(s.z + 0.2, 0.055) - 0.0275);
      k = min(k, max(max(length(kb) - 0.012, abs(s.y - 0.045) - 0.012), max(abs(s.x) - 0.5, abs(s.z + 0.1) - 0.075)));
    }
    lq = s; U(d, k, 9.0);
    lq = p;
  } else U(d, k, 4.0);
  vec3 c; float b;
  for (int i = 0; i < 4; i++){
    c = i == 0 ? PM : i == 1 ? PF : i == 2 ? PA : PB;
    b = length(p - c - vec3(0.0, i < 2 ? 0.95 : 1.05, i < 2 ? -0.1 : -0.15)) - (i < 2 ? 1.22 : 1.0);
    if (b < d){
      if (b < 0.12){
        gDet = gLod[i] < 7.0; gDetH = gLod[i] < 4.5;
        vec3 q = p - c;
        if (i == 0) male(d, q); else if (i == 1) female(d, q); else dj(d, q, float(i - 2));
      } else { d = b; gid = 20.0; gw = float(i); }
    }
  }
  cw = 9.0; lq = p;
  b = length(p - FB - vec3(0.0, 0.8, 0.0)*fsc) - 1.1*fsc;
  if (b < d){ if (b < 0.1) flower(d, p - FB); else { d = b; gid = 32.0; } }
  return d;
}
float map(vec3 p){ return scene(p); }

// ---------------------------------------------------------------- the timeline: what is on screen at second t

vec3 orbit(vec3 c, float r, float h, float a){ return c + vec3(sin(a)*r, h, -cos(a)*r); }
void dropShot(float t, float t0, out vec3 ro, out vec3 ta){
  float i = mod(floor((t - t0)/(BAR*2.0)), 5.0), u = mod(t - t0, BAR*2.0);
  if (i < 0.5){ ro = vec3(-14.0 + u, 1.0, -16.0 + u); ta = vec3(0.0, 1.8, 2.0); }
  else if (i < 1.5){ ro = PA + vec3(-0.75 + 0.1*u, 1.78, -1.25); ta = PA + vec3(0.0, 1.38, -0.12); }
  else if (i < 2.5){ ro = PB + vec3(0.75 - 0.1*u, 1.78, -1.25); ta = PB + vec3(0.0, 1.38, -0.12); }
  else if (i < 3.5){ ro = vec3(0.0, 2.2 + 0.2*u, 5.4); ta = vec3(0.0, 1.0, -3.0); }
  else { ro = vec3(0.6 - 0.3*u, 0.5, -1.0); ta = vec3(0.0, 1.2, 2.2); }
}

// where everyone's joints are at second T (their own space: feet at 0, facing -z)
void legs(inout Rig r, float w){
  r.aR = vec3(-w, 0.09, 0.0); r.aL = vec3(w, 0.09, -0.04);
  r.kR = ik(vec3(-0.09, 0.93 + r.bob, 0.0), r.aR, 0.44, 0.44, vec3(-0.15, 0.0, -1.0));
  r.kL = ik(vec3(0.09, 0.93 + r.bob, 0.0), r.aL, 0.44, 0.44, vec3(0.15, 0.0, -1.0));
}
float look(vec3 c){ vec3 v = gCam - c; return v.z < -0.3 ? clamp(0.6*atan(v.x, -v.z), -0.55, 0.55)*ease(7.0, 4.0, length(v)) : 0.0; }
void pose(){
  float syl = 0.25 + 0.75*abs(sin(T*6.6))*(0.55 + 0.45*sin(T*2.3 + 1.0));
  float singF = (ease(64.4, 64.7, T) - ease(93.6, 94.2, T)) + (ease(121.8, 122.1, T) - ease(141.0, 142.0, T)) + (ease(147.8, 148.1, T) - ease(196.5, 197.5, T));
  float singM = (ease(93.8, 94.1, T) - ease(109.5, 110.5, T)) + (ease(147.8, 148.1, T) - ease(196.5, 197.5, T));
  // the guitarist
  float st = sin(T*6.2832/(BEAT*0.5));
  RM.bob = -0.018*pul; RM.lean = 0.05;
  GO = vec3(0.03, 0.99 + RM.bob, -0.165);
  RM.sR = leanP(vec3(-0.19, 1.4, 0.0), RM.lean, RM.bob); RM.sL = leanP(vec3(0.19, 1.4, 0.0), RM.lean, RM.bob);
  vec3 Gy = vec3(rot(GA)*vec2(0.0, 1.0), 0.0);
  RM.hfR = normalize(-Gy + vec3(0.0, 0.0, 0.2)); RM.hnR = orth(vec3(-0.3, 0.2, -1.0), RM.hfR); RM.cR = 0.8;
  RM.wR = gpt(vec3(-0.04, 0.095 + 0.03*st, -0.07));
  float ch = floor(T/(BEAT*4.0)), fr = fract(T/(BEAT*4.0));
  float cp = mix(0.33 + 0.16*hash(ch + 6.0), 0.33 + 0.16*hash(ch + 7.0), ease(0.0, 0.12, fr));
  RM.hfL = normalize(Gy + vec3(0.0, 0.0, -0.05)); RM.hnL = orth(vec3(0.0, -0.3, -1.0), RM.hfL); RM.cL = 0.92;
  RM.wL = gpt(vec3(cp, -0.118, -0.042));
  RM.eR = ik(RM.sR, RM.wR, UA, FA, vec3(-1.0, -0.2, 0.5));
  RM.eL = ik(RM.sL, RM.wL, UA, FA, vec3(0.6, -1.0, 0.25));
  legs(RM, 0.14);
  RM.mo = clamp(singM, 0.0, 1.0)*syl; RM.nod = 0.05 + 0.05*pul; RM.turn = look(PM + vec3(0.0, 1.6, 0.0));
  // the singer: the mic low at her chin and to her right, the other hand talking
  RF.bob = -0.02*pul; RF.lean = 0.0;
  float g = 0.5 + 0.5*sin(T*6.2832/(BEAT*4.0));
  vec3 bb = vec3(0.0, RF.bob, 0.0);
  micB = vec3(-0.03, 1.5, -0.15) + bb; micA = vec3(-0.135, 1.325, -0.215) + bb;
  vec3 m = normalize(micB - micA);
  RF.hnR = orth(vec3(-0.5, 0.0, -0.85), m); RF.hfR = cross(RF.hnR, m); RF.cR = 1.2;
  RF.wR = micA + m*0.065 - RF.hfR*0.082 + RF.hnR*0.03;
  RF.sR = leanP(vec3(-0.2, 1.39, 0.0), 0.0, RF.bob); RF.sL = leanP(vec3(0.2, 1.39, 0.0), 0.0, RF.bob);
  RF.wL = vec3(0.14 - 0.06*g, 1.2 + 0.07*g, -0.27 - 0.04*g) + bb;
  RF.hfL = normalize(vec3(-0.85, 0.2, -0.4)); RF.hnL = orth(vec3(0.1, 0.9, -0.5), RF.hfL); RF.cL = 0.2 + 0.25*g;
  RF.eR = ik(RF.sR, RF.wR, UA, FA, vec3(-0.7, -1.0, 0.3));
  RF.eL = ik(RF.sL, RF.wL, UA, FA, vec3(1.0, -0.7, 0.2));
  legs(RF, 0.17);
  RF.mo = clamp(singF, 0.0, 1.0)*syl; RF.nod = 0.02 + 0.04*pul; RF.turn = look(PF + vec3(0.0, 1.6, 0.0));
  // the DJs, bent over the booth
  for (int i = 0; i < 2; i++){
    Rig r; float w = float(i), mv = sin(T*6.2832/BEAT + w*2.0), sl = sin(T*6.2832/(BAR*2.0) + w);
    r.bob = -0.02*pul; r.lean = 0.3 + 0.04*pul;
    r.sR = leanP(vec3(-0.2, 1.38, 0.0), r.lean, r.bob); r.sL = leanP(vec3(0.2, 1.38, 0.0), r.lean, r.bob);
    if (i == 0){ r.wR = vec3(-0.36 + 0.035*mv, 1.165, -0.44); r.wL = vec3(0.07 + 0.05*sl, 1.19 + 0.008*mv, -0.42); }
    else { r.wR = vec3(-0.22 + 0.1*sl, 1.215, -0.4 + 0.01*mv); r.wL = vec3(0.2 + 0.06*sl, 1.215, -0.4 - 0.01*mv); }
    r.hfR = normalize(vec3(0.05, -0.4, -1.0)); r.hnR = orth(vec3(0.0, 1.0, 0.0), r.hfR); r.cR = 0.45 + 0.15*mv;
    r.hfL = normalize(vec3(-0.05, -0.4, -1.0)); r.hnL = r.hnR; r.cL = 0.45 - 0.15*mv;
    r.eR = ik(r.sR, r.wR, UA, FA, vec3(-1.0, -0.3, 0.7)); r.eL = ik(r.sL, r.wL, UA, FA, vec3(1.0, -0.3, 0.7));
    legs(r, 0.13);
    r.mo = 0.0; r.nod = 0.28 + 0.22*pul; r.turn = 0.12*sl;
    if (i == 0) RA = r; else RB = r;
  }
}

void direct(float t, out vec3 ro, out vec3 ta, out float roll, out float fl){
  T = t; roll = 0.0; fl = 1.7;
  float drum = (t > 33.2 && t < 35.2) || (t > 42.0 && t < 42.9) || (t > 47.7 && t < 141.5) || (t > 150.0 && t < 157.1) || (t > 162.95 && t < 209.5) ? 1.0 : 0.0;
  pul = drum*exp(-fract(t/BEAT)*6.0);
  float barN = floor(t/BAR);
  dawn = ease(209.5, 221.0, t);
  // light
  crossI = (t < 33.2 ? 0.0 : 1.0)*(0.5 + 1.2*pul) + hit(t, 33.22, 4.0, 2.0) + hit(t, 42.02, 3.0, 3.0) + hit(t, 162.97, 5.0, 1.5);
  crossI = max(crossI, 0.6*ease(5.0, 22.0, t)*step(t, 33.2));
  veins = ease(47.6, 48.2, t)*(1.0 - 0.45*ease(141.5, 144.0, t)*(1.0 - ease(162.8, 163.1, t)))*(1.0 - ease(209.5, 218.0, t));
  if (t > 35.2 && t < 47.7) crossI = 0.35 + 0.15*sin(t*3.0) + hit(t, 42.02, 3.0, 3.0) + ease(42.9, 47.7, t)*step(0.5, fract(t*(2.0 + 6.0*ease(42.9, 47.7, t))));
  if (t > 141.5 && t < 162.95) crossI = 0.4 + 0.6*pul;
  beamI = ease(47.5, 48.0, t)*(1.0 - 0.8*ease(141.0, 142.5, t)) + 0.8*ease(162.8, 163.0, t);
  beamI *= 1.0 - ease(209.0, 215.0, t);
  spotI = ease(47.7, 49.0, t)*(1.0 - 0.6*ease(141.0, 143.0, t)*(1.0 - ease(147.5, 148.5, t)));
  spotI = max(spotI, 0.18*ease(1.0, 6.0, t)*(1.0 - dawn));
  beamC = mod(barN, 2.0) < 0.5 ? vec3(0.1, 0.7, 1.0) : vec3(1.0, 0.15, 0.6);
  if (t > 64.5 && t < 110.5) beamC = mod(barN, 2.0) < 0.5 ? vec3(1.0, 0.6, 0.2) : vec3(1.0, 0.35, 0.1);
  if (t > 121.5 && t < 148.0) beamC = mod(barN, 2.0) < 0.5 ? vec3(1.0, 0.1, 0.35) : vec3(0.7, 0.1, 1.0);
  if (t > 162.95 && t < 178.0) beamC = mod(barN, 2.0) < 0.5 ? vec3(1.0) : vec3(1.0, 0.75, 0.3);
  // the grade, by section: cool intro, cyan and magenta drop, amber chorus, magenta bridge, white gold, then dawn
  gTint = vec3(0.92, 1.0, 1.1);
  gTint = mix(gTint, vec3(1.0, 1.0, 1.06), ease(47.5, 48.0, t));
  gTint = mix(gTint, vec3(1.1, 1.0, 0.88), ease(64.3, 64.9, t));
  gTint = mix(gTint, vec3(1.0, 1.0, 1.04), ease(110.3, 111.0, t));
  gTint = mix(gTint, vec3(1.08, 0.93, 1.08), ease(121.3, 122.0, t));
  gTint = mix(gTint, vec3(0.95, 1.0, 1.08), ease(141.5, 143.0, t));
  gTint = mix(gTint, vec3(1.08, 1.03, 0.92), ease(162.8, 163.1, t));
  gTint = mix(gTint, vec3(1.02, 1.0, 1.0), ease(178.0, 179.0, t));
  gTint = mix(gTint, vec3(1.1, 1.0, 0.9), dawn);
  drop = hit(t, 47.74, 1.0, 1.2) + hit(t, 162.97, 1.0, 0.8);
  // weather
  rain = 1.0 - 0.8*ease(141.5, 144.0, t)*(1.0 - ease(161.0, 163.0, t)) - ease(209.5, 216.0, t);
  wind = rain;
  wave = 1.0 + 0.8*ease(94.0, 104.0, t)*(1.0 - ease(108.0, 112.0, t)) - 0.6*ease(141.5, 145.0, t)*(1.0 - ease(160.0, 163.0, t)) - 0.7*ease(209.5, 220.0, t);
  ring = t > 103.0 && t < 108.5 ? mix(70.0, 5.0, ease(103.0, 106.3, t)) : 1e3;
  lit = hit(t, 3.0, 1.0, 6.0) + hit(t, 11.6, 0.8, 6.0) + hit(t, 19.05, 1.0, 6.0) + hit(t, 26.7, 0.7, 6.0) + hit(t, 30.5, 1.0, 5.0)
      + hit(t, 42.02, 1.0, 5.0) + hit(t, 95.84, 1.0, 4.0) + hit(t, 98.0, 1.0, 4.0) + hit(t, 100.0, 1.2, 4.0) + hit(t, 128.4, 1.0, 4.0)
      + hit(t, 162.97, 1.2, 3.0) + hit(t, 173.47, 0.8, 5.0) + hit(t, 193.98, 0.8, 5.0);
  if (drum > 0.5 && mod(barN, 8.0) < 0.5) lit += hit(t, barN*BAR, 0.5, 7.0);
  lit *= 0.65 + 0.35*step(0.4, hash(floor(t*24.0)));
  boltA = hash(floor(t*0.3 + 0.5) + 3.0)*6.2832;
  bloom = 0.35*ease(141.5, 148.0, t) + 0.65*ease(156.0, 164.5, t);
  fsc = 1.0 + 1.3*ease(162.97, 166.0, t);
  gSun = mix(vec3(0.08, 0.09, 0.14) + lit*vec3(0.5, 0.55, 0.8), vec3(1.0, 0.55, 0.3)*1.2, dawn);
  gFog = 0.012 + 0.03*hit(t, 106.3, 1.0, 0.5);
  fade = ease(0.0, 3.0, t)*(1.0 - ease(221.5, 224.9, t));
  whiteout = hit(t, 33.22, 0.5, 5.0) + hit(t, 42.02, 0.4, 6.0) + hit(t, 47.74, 0.5, 5.0) + hit(t, 106.3, 0.9, 1.2)
           + hit(t, 128.4, 0.8, 4.0) + hit(t, 162.97, 1.0, 2.0) + 0.15*lit;

  vec3 fh = FB + vec3(0.0, 1.3*fsc, 0.0);
  if (t < 16.0){ float s = ease(0.0, 16.0, t); ro = mix(vec3(-22.0, 4.0, -50.0), vec3(-7.0, 2.2, -19.0), s); ta = vec3(0.0, 1.0, 0.0); }
  else if (t < 24.8){ ro = orbit(FB + vec3(0.0, 0.0, 0.0), 1.7, 1.1, -0.6 + 0.05*(t - 16.0)); ta = fh; }
  else if (t < 33.22){ float s = ease(24.8, 33.22, t); ro = vec3(mix(-4.5, -1.6, s), 1.6, 0.9); ta = vec3(0.0, 1.2, 3.0); }
  else if (t < 34.17){ ro = vec3(0.0, 0.9, -3.2); ta = vec3(0.0, 1.0, 2.2); }
  else if (t < 35.2){ ro = vec3(0.6, 0.9, 1.0); ta = vec3(0.0, 0.8, 2.2); }
  else if (t < 42.02){ ro = orbit(vec3(0.0, 0.0, 2.6), 3.2, 1.3, -0.9 + 0.25*(t - 35.2)); ta = vec3(0.0, 1.1, 2.6); }
  else if (t < 42.9){ ro = vec3(0.0, 7.0, 0.5); ta = vec3(0.0, 0.0, 1.5); }
  else if (t < 47.74){ float s = ease(42.9, 47.74, t); ro = mix(vec3(0.0, 0.4, -1.5), vec3(0.0, 9.0, -10.0), s*s); ta = vec3(0.0, 1.0, 1.5); }
  else if (t < 64.6) dropShot(t, 47.74, ro, ta);
  else if (t < 68.8){ float s = ease(64.6, 68.8, t); ro = PF + mix(vec3(-0.3, 1.5, -2.4), vec3(-0.15, 1.55, -1.3), s); ta = PF + vec3(0.0, 1.45, 0.0); }
  else if (t < 72.0){ ro = PF + vec3(-1.2, 1.3, -0.9); ta = PF + vec3(0.0, 1.45, -0.05); }
  else if (t < 75.0){ ro = orbit(FB, 1.5, 0.9, 0.4 - 0.15*(t - 72.0)); ta = fh; }
  else if (t < 79.0){ ro = FB + vec3(0.0, 0.6, -2.0); ta = mix(fh, vec3(0.0, 25.0, 10.0), ease(75.5, 78.5, t)); }
  else if (t < 83.0){ ro = orbit(vec3(0.0, 0.0, 1.0), 9.0, 4.0, -0.6 + 0.15*(t - 79.0)); ta = vec3(0.0, 1.0, 1.0); }
  else if (t < 87.0){ ro = vec3(0.0, 1.5, 0.0 + 0.1*(t - 83.0)); ta = vec3(0.0, 1.3, 3.2); }
  else if (t < 90.0){ ro = FB + vec3(0.4, 1.6, 1.6); ta = FB + vec3(0.0, 0.8, -6.0); }
  else if (t < 94.0){ float s = ease(90.0, 94.0, t); ro = PF + mix(vec3(0.2, 1.6, -1.0), vec3(0.12, 1.61, -0.7), s); ta = PF + vec3(0.0, 1.6, 0.0); }
  else if (t < 95.84){ float s = ease(94.0, 95.84, t); ro = PM + mix(vec3(0.3, 1.5, -1.6), vec3(0.15, 1.55, -1.1), s); ta = PM + vec3(0.0, 1.5, 0.0); }
  else if (t < 101.0 && (t < 97.143 || t >= 99.048)){ float s = ease(94.0, 101.0, t); ro = mix(vec3(-18.0, 0.5, -22.0), vec3(-11.0, 1.2, -14.0), s); ta = vec3(0.0, 2.5, 0.0); }
  else if (t < 101.0){ float u = t - 97.143; ro = PM + vec3(0.4 - 0.1*u, 1.24, -1.1); ta = PM + vec3(0.16, 1.03, -0.18); fl = 3.0; }   // his hands, in the lightning
  else if (t < 104.8){ ro = PM + vec3(-1.5, 1.4, -1.5); ta = PM + vec3(0.0, 1.4, 0.0); }
  else if (t < 110.5){ ro = vec3(10.0, 7.0, -18.0); ta = vec3(0.0, 0.0, 0.0); }
  else if (t < 118.0){ float s = ease(110.5, 118.0, t); ro = orbit(vec3(0.0), mix(14.0, 40.0, s), mix(3.0, 30.0, s), 0.5 + 0.3*(t - 110.5)); ta = vec3(0.0, mix(1.0, 6.0, s), 0.0); }
  else if (t < 122.0){
    float s = ease(118.0, 122.0, t);
    vec3 a = orbit(vec3(0.0), 40.0, 30.0, 0.5 + 0.3*7.5);
    ro = mix(a, PF + vec3(0.4, 1.55, -3.0), s); ta = mix(vec3(0.0, 6.0, 0.0), PF + vec3(0.0, 1.55, 0.0), s);
  }
  else if (t < 126.05){ float s = ease(122.0, 126.05, t); ro = PF + mix(vec3(0.4, 1.55, -3.0), vec3(0.15, 1.6, -1.0), s); ta = PF + vec3(0.0, 1.55, 0.0); }
  else if (t < 129.0){ ro = PF + vec3(-0.6, 0.8, -1.3); ta = PF + vec3(0.0, 1.5, 0.0); }
  else if (t < 133.0){ ro = orbit(PF, 1.6, 1.5, -0.8 + 0.4*(t - 129.0)); ta = PF + vec3(0.0, 1.45, 0.0); }
  else if (t < 137.0){ ro = vec3(0.0, 1.5, -4.2 + 0.2*(t - 133.0)); ta = vec3(0.0, 1.3, 0.3); }
  else if (t < 141.5){ float s = ease(137.0, 141.5, t); ro = PF + mix(vec3(0.2, 1.6, -0.9), vec3(0.12, 1.61, -0.65), s); ta = PF + vec3(0.0, 1.6, 0.0); }
  else if (t < 148.0){ float s = ease(141.5, 148.0, t); ro = FB + vec3(0.3, mix(0.5, 1.2, s), -1.6); ta = mix(fh, vec3(0.0, 30.0, 8.0), ease(144.0, 147.5, t)); }
  else if (t < 152.7){ ro = vec3(0.0, 1.2, -5.5 + 0.2*(t - 148.0)); ta = vec3(0.0, 1.2, 1.0); }
  else if (t < 156.0){ ro = vec3(-3.2, 1.8, 1.8); ta = vec3(0.0, 1.3, 3.2); }
  else if (t < 159.25){ ro = orbit(FB, 1.6, 1.3, 0.5 - 0.1*(t - 156.0)); ta = fh; }
  else if (t < 162.97){ float s = ease(159.25, 162.97, t); ro = mix(vec3(0.0, 1.3, 5.7), vec3(0.0, 7.5, 6.3), s); ta = vec3(0.0, 1.0, -2.0); }
  else if (t < 164.88){ ro = vec3(0.0, 0.6, -7.5); ta = vec3(0.0, 2.0, 0.0); }
  else if (t < 168.45){ ro = PF + vec3(-0.5, 1.5, -1.8); ta = PF + vec3(0.0, 1.5, 0.0); }
  else if (t < 172.14){ ro = PM + vec3(0.5, 1.5, -1.8); ta = PM + vec3(0.0, 1.45, 0.0); }
  else if (t < 175.0){ ro = orbit(FB, 3.0, 0.3, -0.3 + 0.2*(t - 172.14)); ta = fh; }
  else if (t < 178.4){ ro = orbit(vec3(0.0, 0.0, 0.3), 4.5, 1.4, -0.4 + 0.25*(t - 175.0)); ta = vec3(0.0, 1.3, 0.3); }
  else if (t < 180.3){ ro = PA + vec3(-0.75, 1.78, -1.25); ta = PA + vec3(0.0, 1.38, -0.12); }
  else if (t < 182.2){ ro = PB + vec3(0.75, 1.78, -1.25); ta = PB + vec3(0.0, 1.38, -0.12); }
  else if (t < 186.0){ ro = orbit(vec3(0.0, 0.0, 1.0), 10.0, 3.0, 0.8 - 0.2*(t - 182.2)); ta = vec3(0.0, 1.5, 1.0); }
  else if (t < 188.3){ ro = vec3(0.0, 12.0, 0.6); ta = vec3(0.0, 0.0, 1.0); roll = (t - 186.0)*0.6; }
  else if (t < 192.2){ ro = orbit(vec3(0.0, 0.0, 0.0), 6.0, 2.5, 0.3 - 0.15*(t - 188.3)); ta = fh; }
  else if (t < 195.0){ ro = vec3(0.0, 1.5, -3.8); ta = vec3(0.0, 1.35, 0.3); }
  else if (t < 209.5) dropShot(t, 195.0, ro, ta);
  else {
    float s = ease(209.5, 222.0, t);
    ro = mix(FB + vec3(0.0, 3.2, 1.5), vec3(0.0, 14.0, 16.0), s);
    ta = mix(fh, vec3(0.0, 3.0, -60.0), ease(209.5, 215.0, t));
  }
  gCam = ro;
  gLod = vec4(length(ro - PM - vec3(0.0, 1.3, 0.0)), length(ro - PF - vec3(0.0, 1.3, 0.0)), length(ro - PA - vec3(0.0, 1.3, 0.0)), length(ro - PB - vec3(0.0, 1.3, 0.0)));
  pose();
}

// ---------------------------------------------------------------- sky, materials, light

vec3 fogCol(){ return mix(vec3(0.018, 0.022, 0.034) + lit*vec3(0.2, 0.22, 0.32), vec3(0.75, 0.42, 0.24), dawn); }

vec3 sky(vec3 rd){
  float a = atan(rd.z, rd.x), e = rd.y, ep = max(e, 0.0);
  // the storm from inside its eye: cloud bands spiral in to a clear hole overhead
  vec2 c = rd.xz/(ep + 0.2);
  float r = length(c);
  float sp = a + 2.4*log(r + 0.12) + T*0.06;
  float w = fbm(vec3(c*0.9, T*0.03));
  float arm = 0.5 + 0.5*sin(sp*2.0 + 3.5*(w - 0.5));
  float cl = fbm(vec3(cos(sp)*r*1.6, sin(sp)*r*1.6, r*1.5 - T*0.08));
  cl = clamp(cl + 0.35*(fbm(vec3(cos(sp)*r*5.0, sin(sp)*r*5.0, r*4.0 - T*0.1)) - 0.5), 0.0, 1.0);
  float dens = ease(0.26, 0.5, r + 0.3*(w - 0.5))*ease(0.25, 0.7, arm*0.75 + cl*0.55 + 0.7*ease(1.6, 3.6, r));
  vec3 col = mix(vec3(0.004, 0.006, 0.014), vec3(0.012, 0.015, 0.026), 1.0 - ep);
  col += step(0.9975, hash(floor(rd*320.0)))*ease(0.45, 0.8, e)*0.7*(1.0 - dawn);
  col += vec3(0.1, 0.12, 0.17)*exp(-r*r*9.0);                                      // moonlight down the eye
  float rim = exp(-max(r - 0.32, 0.0)*1.25);
  vec3 cc = vec3(0.014, 0.017, 0.027)*(0.4 + 1.2*cl);
  cc += vec3(0.2, 0.24, 0.33)*rim*(0.12 + 1.5*cl*cl)*(0.35 + 0.65*arm);            // the eyewall, lit from the eye
  cc += lit*vec3(0.5, 0.55, 0.8)*(0.15 + cl*cl*1.6)*(0.4 + 0.6*arm);
  col = mix(col, cc, dens*(1.0 - 0.5*dawn));
  col = mix(col, fogCol(), exp(-ep*9.0)*0.8*(1.0 - dawn));
  col += beamC*0.05*exp(-abs(e)*7.0)*beamI;
  // the bolt, with two branches
  float dx = atan(sin(a - boltA), cos(a - boltA)) + 0.07*(noise(vec2(e*12.0, boltA)) - 0.5) + 0.025*(noise(vec2(e*45.0, boltA)) - 0.5);
  float bd = e > 0.0 && e < 0.55 ? abs(dx) : 1.0;
  for (int i = 0; i < 2; i++){
    float fi = float(i), e0 = 0.38 - 0.16*fi, sg = fi < 0.5 ? 1.0 : -1.0;
    float bx = dx - sg*(e0 - e)*(0.55 + 0.25*fi) - 0.03*(noise(vec2(e*30.0, boltA + fi)) - 0.5);
    if (e < e0 && e > e0 - 0.2 - 0.06*fi) bd = min(bd, abs(bx)*1.6);
  }
  col += vec3(0.8, 0.85, 1.0)*(ease(0.007, 0.0, bd)*3.0 + 0.02/(bd + 0.02))*lit*step(0.0, e);
  vec3 sd = normalize(vec3(0.2, 0.04, -1.0));
  vec3 dc = mix(vec3(1.0, 0.5, 0.25), vec3(0.25, 0.4, 0.7), clamp(e*2.5, 0.0, 1.0))*(0.6 + 0.4*cl);
  dc = mix(dc, vec3(1.0, 0.55, 0.4)*(0.35 + 0.5*cl), dens*0.45*ease(0.0, 0.3, e));
  dc += vec3(1.0, 0.7, 0.35)*(pow(max(dot(rd, sd), 0.0), 400.0)*6.0 + pow(max(dot(rd, sd), 0.0), 8.0)*0.6);
  return mix(col, dc, dawn);
}

struct Mat { vec3 alb; float spec, gloss, sss, refl; vec3 emi; };

// a thin line every 1 unit of x, w wide, fading to its average where it would shimmer (fw: a pixel, in units)
float line(float x, float w, float fw){
  float f = abs(fract(x) - 0.5);
  return mix(1.0 - ease(w*0.5 - fw*0.5, w*0.5 + fw*0.5, f), w, clamp(fw*1.4 - 0.4, 0.0, 1.0));
}
vec3 pin(float x, float fw){ return mix(vec3(0.17, 0.18, 0.21), vec3(0.62, 0.63, 0.66), line(x, 0.3, fw)); }

Mat mat(vec3 p, inout vec3 n, float id, vec3 q, float w, float t){
  Mat m = Mat(vec3(0.2), 0.1, 16.0, 0.0, 0.0, vec3(0.0));
  float px = t/(1.7*0.5*min(iResolution.x, iResolution.y));          // the size of a pixel there
  if (id < 0.5){
    // the sea: foam on the crests, on the big wave, and where it breaks on rock
    float k = length(p.xz - vec2(0.0, 0.5)) - ring, big = (3.2 + 3.3*ease(45.0, 9.0, ring))*exp(-k*k*(k < 0.0 ? 0.05 : 0.012));
    float hgt = (p.y + 4.0 - big)/max(wave, 0.3);
    float tex = fbm(p.xz*1.7 + vec2(T*0.5, T*0.2)), tex2 = noise(vec2(dot(p.xz, vec2(0.8, 0.6))*0.25 + T*0.3, dot(p.xz, vec2(-0.6, 0.8))*2.2));
    float foam = ease(0.95, 1.5, hgt + 0.9*(tex - 0.5)) + 0.35*ease(0.62, 0.8, tex2)*ease(0.2, 0.9, hgt)*wind;
    float rk = min(rockBase(p), stacks(p) + 0.6);
    foam += ease(2.2, 0.2, rk + 0.5*sin(T*1.4 + 4.0*tex))*ease(0.3, 0.55, tex + 0.25*ease(1.0, 0.0, rk));
    foam += (ease(0.5, 0.9, exp(-k*k*0.35) + 0.6*(tex - 0.5)) + 0.6*ease(0.55, 0.75, tex2)*exp(-k*k*0.03)*step(k, 0.5))*ease(100.0, 60.0, ring);
    foam = clamp(foam, 0.0, 1.0)*ease(120.0, 40.0, t);
    m.alb = mix(vec3(0.004, 0.012, 0.017) + vec3(0.0, 0.03, 0.03)*ease(0.6, 1.6, hgt) + vec3(0.0, 0.05, 0.045)*exp(-k*k*0.04)*ease(100.0, 60.0, ring), vec3(0.55, 0.6, 0.62), foam);
    m.spec = 1.0 - 0.8*foam; m.gloss = 120.0; m.refl = 1.0 - foam;
    vec2 e = vec2(0.05, 0.0), w2 = p.xz*2.3 + vec2(T*1.1, T*0.4);
    float dn = ease(90.0, 10.0, t)*(0.5 + 0.5*wind);
    n = normalize(n + dn*vec3(fbm(w2 - e.xy) - fbm(w2 + e.xy), 0.0, fbm(w2 - e.yx) - fbm(w2 + e.yx))*1.6);
    return m;
  }
  if (id < 1.5){
    // basalt: strata, lichen on top faces, a dark wet band at the waterline; puddles on the flat top
    float f = fbm(p*1.3), top = ease(0.75, 0.95, n.y)*ease(0.2, 0.0, abs(p.y));
    m.alb = vec3(0.05, 0.047, 0.05)*(0.45 + 1.1*f)*(0.8 + 0.4*ease(0.3, 0.7, fract(p.y*0.55 + 1.2*fbm(p*0.45))));
    m.alb = mix(m.alb, vec3(0.085, 0.095, 0.05), ease(0.55, 0.75, n.y)*ease(0.5, 0.62, fbm(p*0.9 + 3.0))*ease(-2.5, -1.0, p.y)*(1.0 - top));
    m.alb *= mix(0.45, 1.0, ease(-3.4, -2.2, p.y + 0.4*f));
    m.spec = 0.14 + 0.3*ease(-2.0, -3.2, p.y); m.gloss = 24.0;
    if (top > 0.0){
      float pud = ease(0.5, 0.42, fbm(p.xz*0.55 + 7.0))*top;
      vec2 cell = floor(p.xz*5.0), o = fract(p.xz*5.0) - 0.5;
      float ph = fract(T*1.3 + hash(cell)*7.0), rg = length(o - 0.25*(vec2(hash(cell + 1.0), hash(cell + 2.0)) - 0.5));
      float rip = ease(0.05, 0.0, abs(rg - ph*0.3))*(1.0 - ph)*(1.0 - ph)*rain*step(0.45, hash(cell + 5.0))*0.5;
      m.alb = mix(m.alb*0.8, vec3(0.012), pud);
      m.spec = mix(0.4, 0.3, pud); m.gloss = mix(50.0, 200.0, pud); m.refl = mix(0.12, 0.9, pud)*top;
      n = normalize(mix(n, vec3(0.0, 1.0, 0.0), pud) + vec3(o.x, 0.0, o.y)*rip*1.5/max(rg, 0.05)*mix(0.3, 1.0, pud));
      m.alb += vec3(0.25)*rip*0.5;
    }
    return m;
  }
  if (id < 3.5){ m.alb = vec3(0.3); m.spec = 0.8; m.gloss = 60.0; return m; }
  if (id < 4.5){
    vec3 b = abs(p - vec3(0.0, 0.5, 2.65)) - vec3(1.9, 0.5, 0.42);
    float e = min(min(max(b.x, b.y), max(b.y, b.z)), max(b.x, b.z));
    vec3 pc = vec3(mod(p.x + 1.9, 0.95) - 0.475, p.y - 0.5, 0.0);
    float edge = max(step(-0.035, e), step(0.455, abs(pc.x))*step(b.z, -0.001)*0.0 + step(abs(abs(pc.x) - 0.475), 0.03));
    float latch = step(length(vec2(abs(pc.x) - 0.3, abs(pc.y) - 0.22)), 0.045)*step(-0.01, b.z);
    if (p.y > 0.999) { edge = step(-0.035, e); latch = 0.0; }
    m.alb = mix(vec3(0.014), vec3(0.42), max(edge, latch)); m.spec = mix(0.25, 0.9, max(edge, latch)); m.gloss = mix(20.0, 80.0, edge);
    m.alb *= 0.7 + 0.5*noise(p*vec3(40.0, 6.0, 40.0));
    return m;
  }
  if (id < 5.5){
    // the cross: plain glowing gold at first, then a visualizer: veins of gold and silver that run up it and flare on the beat
    vec2 c = vec2(p.x, p.y - 4.7);
    vec3 gold = vec3(1.0, 0.72, 0.3), silver = vec3(0.8, 0.88, 1.0);
    float flow = T*0.35, rad = length(c);
    vec2 wq = c*0.55 + 0.6*vec2(fbm(c*0.7 + vec2(0.0, -flow)), fbm(c*0.7 + vec2(5.2, -flow*0.8)));
    float v1 = 1.0 - clamp(abs(fbm(wq*1.3 + vec2(0.0, -flow*0.6)) - 0.5)*18.0, 0.0, 1.0);
    float v2 = 1.0 - clamp(abs(fbm(wq*2.1 + vec2(7.0, -flow) + 3.0) - 0.5)*12.0, 0.0, 1.0);
    float v3 = 1.0 - clamp(abs(noise(wq*6.0 + vec2(2.0, -flow*1.5)) - 0.5)*7.0, 0.0, 1.0);
    float ringw = exp(-pow((rad - fract(T/BEAT)*4.5)*1.4, 2.0))*pul;
    float g = pow(v1, 3.0)*2.4 + pow(v3, 4.0)*0.5*(0.2 + pul) + v1*0.06, sv = pow(v2, 3.0)*2.6 + v2*0.04;
    vec3 vis = gold*(g*(0.7 + 1.2*pul) + 0.012 + 0.12*ringw + 1.5*ringw*g) + silver*sv*(0.7 + 0.5*sin(T*2.1 + rad*2.0) + 1.5*ringw);
    vec3 bb = abs(vec3(c, 0.0)); float edge = ease(0.12, 0.0, min(abs(max(bb.x - 0.75, bb.y - 3.6 - 1.1*0.0)), 1.0))*0.0;
    m.alb = vec3(0.012, 0.009, 0.005);
    m.emi = mix(gold*1.7, vis*2.2, veins)*crossI*(abs(n.z) > 0.5 ? 1.0 : 0.7 + 0.0*edge);
    m.spec = 0.15; m.gloss = 40.0;
    return m;
  }
  if (id < 6.5){
    // decks and mixer: platters with a groove sheen, knobs, faders, and LEDs on the beat
    float dx = abs(q.x) - 0.47, r = length(vec2(dx, q.z));
    m.alb = vec3(0.022); m.spec = 0.5; m.gloss = 50.0;
    if (q.y > 0.045 && r < 0.146){ m.alb = vec3(0.03) + 0.05*line(r*90.0, 0.4, px*90.0); m.spec = 0.9; m.gloss = 30.0 + 60.0*fract(r*33.0); if (r < 0.04) m.alb = vec3(0.6, 0.1, 0.08); }
    else if (abs(q.x) < 0.15){
      if (q.y > 0.06) m.alb = vec3(0.35);
      vec2 g = vec2(floor((q.x + 0.125)/0.05), floor((q.z + 0.17)/0.06));
      float led = step(length(vec2(mod(q.x + 0.125, 0.05) - 0.025, mod(q.z + 0.17, 0.06) - 0.03 - 0.022)), 0.005)*step(q.z, 0.13)*step(q.y, 0.06);
      m.emi = led*pal(hash(g) + T*0.05, vec3(0.5), vec3(0.5), vec3(1.0), vec3(0.0, 0.33, 0.67))*(0.3 + 2.0*pul*step(0.5, hash(g + floor(T/BEAT))));
      float vu = step(abs(q.x), 0.012)*step(q.z, 0.17)*step(0.13, q.z + 0.3*step((q.z + 0.15)/0.3, 0.2 + 0.8*pul));
      m.emi += vec3(0.1, 1.0, 0.3)*step(abs(abs(q.x) - 0.006), 0.004)*step(abs(q.z - 0.02), 0.13)*step(fract(q.z*60.0), 0.6)*step((q.z + 0.11)/0.26, 0.25 + 0.75*pul)*0.8 + 0.0*vu;
    } else if (q.y > 0.03){
      float led = step(length(vec2(dx + 0.15, q.z + 0.15)), 0.012);
      m.emi = led*vec3(1.0, 0.25, 0.1)*(0.5 + pul);
    }
    return m;
  }
  if (id < 7.5){
    float pl = p.x*3.3, e = ease(0.03, 0.0, abs(fract(pl) - 0.5) - 0.47);
    m.alb = vec3(0.07, 0.05, 0.035)*(0.5 + 0.9*noise(vec2(floor(pl)*7.0 + p.x*2.0, p.z*30.0)))*(1.0 - 0.7*e);
    m.spec = 0.5; m.gloss = 40.0; m.refl = 0.06;
    return m;
  }
  if (id < 8.5){
    // a lamp: its lens glows the colour of the beams (the rear pair) or warm (the front pair)
    vec3 ax = normalize(vec3(-0.2, -0.14, -0.13));
    float lens = ease(0.16, 0.2, dot(q - vec3(0.0, 6.28, 0.0), ax));
    bool rear = p.z > 0.5;
    m.alb = vec3(0.02); m.spec = 0.6; m.gloss = 40.0;
    m.emi = lens*(rear ? beamC*(0.25*spotI + beamI*(3.0 + 3.0*pul)) : vec3(1.0, 0.85, 0.7)*spotI*5.0);
    return m;
  }
  if (id < 9.5){
    // the synth: keys toward the player, knobs and lights at the back
    m.alb = vec3(0.03); m.spec = 0.5; m.gloss = 60.0;
    if (q.y > 0.03 && abs(q.x) < 0.52){
      if (q.z > 0.02){
        float kx = q.x*42.0, kk = mod(floor(kx), 7.0);
        float black = step(q.z, 0.12)*step(abs(fract(kx + 0.5) - 0.5), 0.3)*(1.0 - step(abs(kk - 2.0), 0.5))*(1.0 - step(abs(kk - 6.0), 0.5));
        m.alb = mix(vec3(0.75)*(1.0 - 0.6*line(kx, 0.08, px*42.0)), vec3(0.02), black); m.spec = 0.9; m.gloss = 90.0;
      } else if (q.y > 0.05) m.alb = vec3(0.3);
      else {
        vec2 g = vec2(floor(q.x/0.07), floor((q.z + 0.2)/0.055));
        float led = step(length(vec2(mod(q.x, 0.07) - 0.035 - 0.022, mod(q.z + 0.2, 0.055) - 0.0275)), 0.005)*step(q.z, -0.03);
        m.emi = led*pal(hash(g)*0.4 + 0.02*T, vec3(0.5), vec3(0.5), vec3(1.0), vec3(0.0, 0.33, 0.67))*(0.4 + 2.0*step(0.6, hash(g + floor(T/(BEAT*0.5)))));
      }
    }
    return m;
  }
  // people. w: 0 the guitarist, 1 the singer, 2 DJ A, 3 DJ B
  if (id < 10.5){
    m.alb = w < 0.5 ? vec3(0.5, 0.31, 0.23) : w < 1.5 ? vec3(0.27, 0.145, 0.095) : w < 2.5 ? vec3(0.48, 0.3, 0.22) : vec3(0.5, 0.33, 0.25);
    m.spec = 0.35 + 0.25*step(0.5, w)*step(w, 1.5); m.gloss = 28.0; m.sss = 1.0;
    // inside the mouth, and a little colour in the cheeks
    if (length(q) < 0.14){
      float inm = ease(0.004, -0.004, sdEll(q - vec3(0.0, -0.062, -0.1), vec3(0.021, 0.02, 0.02)))*ease(-0.103, -0.097, q.z);
      m.alb = mix(m.alb, vec3(0.07, 0.01, 0.012), inm);
      m.alb = mix(m.alb, m.alb*vec3(1.25, 0.8, 0.8), ease(0.04, 0.0, length(vec3(abs(q.x) - 0.045, q.y + 0.03, q.z + 0.085)))*0.5);
    }
    return m;
  }
  if (id < 11.5){
    // light brown, streaked blond, lighter toward the tips
    float sk = noise(vec2(q.x*0.11, q.y*1.5)), fine = 0.85 + 0.15*sin(q.x*0.9) + 0.1*sin(q.x*0.23 + 1.0);
    m.alb = mix(vec3(0.17, 0.105, 0.055), vec3(0.62, 0.46, 0.22), ease(0.42, 0.72, sk)*0.85 + 0.25*ease(1.55, 1.25, q.y))*fine;
    m.spec = 0.7; m.gloss = 30.0; m.sss = 0.4; return m;
  }
  if (id < 12.5){ m.alb = vec3(0.42, 0.055, 0.03)*(0.3 + 1.0*ease(0.45, 1.3, q.x))*mix(1.0, 1.5, ease(1.5, 1.1, q.y)); m.spec = 0.4; m.gloss = 18.0; m.sss = 0.5; return m; }
  if (id < 13.5){ m.alb = vec3(0.055, 0.035, 0.022)*(0.35 + 0.9*ease(0.4, 1.2, q.x)); m.spec = 0.35; m.gloss = 18.0; return m; }
  if (id < 14.5){ m.alb = vec3(0.022, 0.017, 0.014)*(0.7 + 0.5*sin(q.x)); m.spec = 0.5; m.gloss = 26.0; return m; }
  if (id < 15.5){ m.alb = (w < 0.5 ? vec3(0.13, 0.08, 0.045) : vec3(0.05, 0.032, 0.02))*(0.6 + 0.8*noise(q*300.0)); m.spec = 0.2; m.gloss = 14.0; return m; }
  if (id < 16.5){
    // an eye: iris and pupil look straight ahead
    vec3 e = normalize(q);
    float c = -e.z;
    m.alb = mix(vec3(0.75, 0.72, 0.68), w > 0.5 && w < 1.5 ? vec3(0.1, 0.045, 0.02) : vec3(0.16, 0.1, 0.05), ease(0.78, 0.81, c));
    m.alb = mix(m.alb, vec3(0.005), ease(0.93, 0.95, c));
    m.spec = 1.5; m.gloss = 200.0;
    return m;
  }
  if (id < 17.5){ m.alb = w > 0.5 && w < 1.5 ? vec3(0.3, 0.07, 0.06) : vec3(0.42, 0.2, 0.17); m.spec = 0.7; m.gloss = 50.0; m.sss = 1.0; return m; }
  if (id < 18.5){ m.alb = w < 0.5 ? vec3(0.1, 0.06, 0.035) : vec3(0.03, 0.02, 0.015); return m; }
  if (id < 19.5){ float sole = step(q.y, 0.022); m.alb = w > 0.5 && w < 1.5 ? mix(vec3(0.55), vec3(0.7), sole) : mix(vec3(0.03, 0.025, 0.02), vec3(0.3), sole*step(0.5, w)); m.spec = 0.5; m.gloss = 30.0; return m; }
  if (id < 20.5){ m.alb = vec3(0.72, 0.71, 0.68); m.spec = 0.05; m.sss = 0.4; return m; }
  if (id < 21.5){ m.alb = vec3(0.028, 0.036, 0.06)*(0.8 + 0.4*noise(p*vec3(300.0, 60.0, 300.0))); m.spec = 0.1; return m; }
  if (id < 22.5){
    // her jacket: pinstripes down the body, and the yellow-green top in the open front
    float u = atan(q.x, -q.z)*0.17/0.016;
    m.alb = pin(u, px/0.016); m.spec = 0.12; m.gloss = 12.0;
    if (abs(q.y - 0.9) < 0.04) m.alb = pin(q.y/0.016, px/0.016);
    return m;
  }
  if (id < 23.5 || (id > 48.5 && id < 49.5) || (id > 50.5 && id < 51.5)){
    // DJ A's dark satin jacket, with a zip
    m.alb = vec3(0.03, 0.038, 0.034); m.spec = 0.6; m.gloss = 18.0;
    if (id < 23.5 && q.z < 0.0 && abs(q.x) < 0.006){ m.alb = vec3(0.35); m.spec = 1.0; }
    return m;
  }
  if (id < 24.5 || id > 49.5){
    // DJ B's black varsity jacket: white block letters across the chest, striped ribs at collar, cuffs and hem
    m.alb = vec3(0.012); m.spec = 0.25; m.gloss = 20.0;
    if (id < 24.5){
      vec2 uv = vec2((q.x + 0.128)/0.0135, (1.345 - q.y)/0.019);
      if (q.z < 0.0 && uv.x >= 0.0 && uv.x < 19.0 && uv.y >= 0.0 && uv.y < 5.0){
        int li = int(uv.x/4.0), cx = int(mod(uv.x, 4.0)), cy = int(uv.y);
        int bits = li == 0 ? 31183 : li == 1 ? 29842 : li == 2 ? 31599 : li == 3 ? 27565 : 24557;
        if (cx < 3 && ((bits >> (14 - (cy*3 + cx))) & 1) == 1) m.alb = mix(m.alb, vec3(0.8), clamp(1.6 - px/0.0135, 0.0, 1.0));
      }
      float rib = max(step(q.y, 0.91), step(1.435, q.y));
      m.alb = mix(m.alb, vec3(0.7), rib*line(q.y/0.02 + 0.25, 0.35, px/0.02));
    } else if (id > 51.5 && q.y > 0.7) m.alb = mix(m.alb, vec3(0.7), line(q.y*6.0, 0.35, px*20.0));
    return m;
  }
  if (id < 25.5){
    // the guitar's top: cream lacquer, a tortoiseshell guard, strings
    m.alb = vec3(0.72, 0.6, 0.38); m.spec = 1.0; m.gloss = 90.0; m.refl = 0.0;
    if (q.z < -0.02){
      float gd = smin(length(q.xy - vec2(-0.05, -0.045)) - 0.08, length(q.xy - vec2(0.08, -0.02)) - 0.07, 0.05);
      if (gd < 0.0) m.alb = mix(vec3(0.16, 0.035, 0.015), vec3(0.45, 0.16, 0.04), ease(0.4, 0.7, noise(q.xy*70.0)))*ease(0.0, -0.004, gd) + vec3(0.6)*ease(-0.004, 0.0, gd);
      if (q.x > -0.205) m.alb = mix(m.alb, vec3(0.75), line((q.y + 0.0045)/0.0075, 0.16, px/0.0075)*step(abs(q.y), 0.021));
    }
    return m;
  }
  if (id < 26.5){
    // the neck: maple, a dark fretboard with frets and strings
    m.alb = vec3(0.45, 0.3, 0.14); m.spec = 0.6; m.gloss = 50.0;
    if (q.z < -0.02 && q.x < 0.665){
      float fx = -log2(max(0.72 - q.x, 0.01)/0.6)*12.0;
      m.alb = mix(vec3(0.045, 0.028, 0.02), vec3(0.6), line(fx, 0.1, px*30.0));
      m.alb = mix(m.alb, vec3(0.75), line((q.y + 0.0045)/0.0075, 0.16, px/0.0075)*step(abs(q.y), 0.021));
    }
    return m;
  }
  if (id < 27.5){ m.alb = vec3(0.016); m.spec = 0.7; m.gloss = 50.0; return m; }
  if (id < 28.5){ m.alb = vec3(0.5, 0.48, 0.42); m.spec = 1.5; m.gloss = 90.0; return m; }
  if (id < 29.5){ m.alb = mix(vec3(0.5, 0.52, 0.08), vec3(0.2, 0.4, 0.1), step(0.5, fract(q.y*14.0))); if (q.y > 1.33) m.alb = vec3(0.27, 0.145, 0.095); m.spec = 0.1; return m; }
  if (id < 30.5){
    // a petal: pale at the base, veined, deeper at the tip
    float u = q.x*0.5 + 0.5;
    m.alb = mix(vec3(0.95, 0.75, 0.8), vec3(0.9, 0.16, 0.36), ease(0.1, 0.9, u))*(0.85 + 0.15*sin(q.y*26.0))*(1.0 - 0.25*q.z);
    m.spec = 0.25; m.gloss = 20.0; m.sss = 2.0;
    m.emi = vec3(1.0, 0.25, 0.45)*(0.05 + 0.5*bloom*(0.7 + 0.3*pul))*m.alb;
    return m;
  }
  if (id < 31.5){ m.alb = vec3(0.9, 0.55, 0.04)*(0.7 + 0.3*sin(length(q.xy)*160.0)); m.emi = vec3(1.0, 0.7, 0.1)*(0.05 + 0.5*bloom*(0.7 + 0.3*pul)); return m; }
  if (id < 33.5 && id > 32.5){ m.alb = vec3(0.25)*(0.5 + 0.5*step(0.5, fract(q.y*220.0))*step(0.5, fract(q.x*220.0))); m.spec = 1.2; m.gloss = 40.0; return m; }
  if (id < 34.5){ m.alb = vec3(0.045, 0.2, 0.035)*(id > 33.5 ? 0.8 + 0.4*ease(0.004, 0.0, abs(q.z)) : 1.0); m.spec = 0.3; m.gloss = 20.0; m.sss = 1.0; return m; }
  if (id < 43.5){ m.alb = pin(q.x*q.z/0.016, px/0.016); if (q.y == 0.5 && q.x == 0.0) m.alb = vec3(0.3, 0.31, 0.34); m.spec = 0.12; m.gloss = 12.0; return m; }
  if (id < 47.5){ m.alb = pin(q.x*q.z/0.016, px/0.016); m.spec = 0.12; m.gloss = 12.0; return m; }
  m.alb = vec3(0.02, 0.022, 0.03); return m;
}

float marchT(vec3 ro, vec3 rd, float tmax, int steps){
  float t = 0.02;
  for (int i = 0; i < 400; i++){
    if (i >= steps) break;
    float d = scene(ro + rd*t);
    if (abs(d) < 0.0004*t) return t;
    t += d*0.9;
    if (t > tmax) return -1.0;
  }
  return t < tmax ? t : -1.0;
}
vec3 normalAt(vec3 p, float t){
  float e = 0.0004*max(t, 0.6); vec2 k = vec2(1.0, -1.0);
  return normalize(k.xyy*scene(p + k.xyy*e) + k.yyx*scene(p + k.yyx*e) + k.yxy*scene(p + k.yxy*e) + k.xxx*scene(p + k.xxx*e));
}
float shadow(vec3 ro, vec3 rd, float far){
  float r = 1.0, t = 0.03;
  for (int i = 0; i < 36; i++){
    float h = scene(ro + rd*t);
    r = min(r, 9.0*h/t); t += clamp(h, 0.02, 0.9);
    if (r < 0.005 || t > far) break;
  }
  return clamp(r, 0.0, 1.0);
}
float ao(vec3 p, vec3 n){
  float o = 0.0, s = 1.0;
  for (int i = 0; i < 5; i++){ float h = 0.015 + 0.11*float(i); o += (h - scene(p + n*h))*s; s *= 0.72; }
  return clamp(1.0 - 1.6*o, 0.0, 1.0);
}

vec3 amb(vec3 n){
  vec3 a = (vec3(0.02, 0.025, 0.038) + lit*vec3(0.12, 0.13, 0.2))*(0.5 + 0.5*n.y);
  return mix(a, mix(vec3(0.3, 0.17, 0.1), vec3(0.16, 0.22, 0.36), n.y*0.5 + 0.5)*0.55, dawn);
}

// one light on one surface: wrapped diffuse (skin, petals let light through), a highlight
vec3 light(vec3 n, vec3 v, Mat m, vec3 l, vec3 lc){
  float nl = dot(n, l), wr = 0.35*min(m.sss, 1.0);
  float dif = max((nl + wr)/(1.0 + wr), 0.0);
  vec3 c = m.alb*dif;
  c += m.alb*vec3(1.0, 0.35, 0.25)*min(m.sss, 1.0)*0.25*ease(-0.35, 0.1, nl)*ease(0.45, 0.1, nl);
  c += m.alb*max(m.sss - 1.0, 0.0)*max(-nl, 0.0)*0.7;
  c += vec3(m.spec)*pow(max(dot(n, normalize(l + v)), 0.0), m.gloss)*(m.gloss + 8.0)/40.0*max(nl, 0.0);
  return c*lc;
}

const vec3 LC = vec3(0.0, 4.4, 6.3), GOLD = vec3(1.0, 0.8, 0.48);
float gRefl = 0.0; vec3 gN = vec3(0.0, 1.0, 0.0);

// the colour of the surface a ray hit at t. full: with shadows and occlusion (the camera's own rays)
vec3 surf(vec3 ro, vec3 rd, float t, bool full){
  vec3 p = ro + rd*t, n = normalAt(p, t), v = -rd;
  scene(p);
  float id = gid, w = gw; vec3 q = gq;
  Mat m = mat(p, n, id, q, w, t);
  float occ = full && id > 0.5 ? ao(p, n) : 1.0;
  vec3 col = m.alb*amb(n)*occ + m.emi;
  // the moon behind the cloud, the lightning, and at the end the sun
  vec3 sd = mix(SUN, normalize(vec3(0.2, 0.12, -1.0)), dawn);
  float nl = dot(n, sd);
  if (nl > -0.4){
    float s = full && nl > 0.0 ? shadow(p + n*0.01, sd, 30.0) : 1.0;
    col += light(n, v, m, sd, gSun*1.5*s);
  }
  // the cross
  vec3 l = LC - p; float dd = dot(l, l);
  col += light(n, v, m, l*inversesqrt(dd), GOLD*crossI*42.0/(4.0 + dd)*ease(7.0, 6.7, p.z)*mix(1.0, occ, 0.5));
  // two warm spots from the front towers, two lights the colour of the beams from the rear ones (the rim)
  for (int i = 0; i < 4; i++){
    vec3 lp = vec3(i == 0 || i == 2 ? -5.75 : 5.75, 6.1, i < 2 ? -3.3 : 4.3);
    l = lp - p; dd = dot(l, l); l *= inversesqrt(dd);
    vec3 lc = i < 2 ? vec3(1.0, 0.85, 0.7)*spotI*55.0 : (vec3(0.5, 0.62, 1.0)*(0.25 + 0.5*spotI)*(1.0 - dawn) + beamC*beamI*(0.8 + 0.8*pul))*48.0;
    lc *= 1.0/(1.0 + dd)*ease(0.5, 0.8, dot(-l, normalize(vec3(0.0, 1.0, 0.5) - lp)));
    if (dot(lc, vec3(1.0)) < 0.004) continue;
    float s = 1.0;
    if (full && i < 2 && dot(n, l) > 0.0 && id > 0.5) s = shadow(p + n*0.01, l, sqrt(dd));
    col += light(n, v, m, l, lc*s*(i < 2 ? 1.0 : mix(1.0, occ, 0.6)));
  }
  // the flower's own glow
  l = FB + vec3(0.0, 1.3*fsc, -0.3) - p; dd = dot(l, l);
  col += light(n, v, m, l*inversesqrt(dd), vec3(1.0, 0.3, 0.5)*bloom*bloom*4.0*fsc/(1.0 + dd));
  // the sky in grazing surfaces, and in the sea
  float fr = pow(1.0 - max(dot(n, v), 0.0), 5.0);
  if (id < 0.5){
    vec3 r = reflect(rd, n); r.y = abs(r.y);
    col += (0.02 + 0.98*fr)*sky(r)*m.refl*0.9;
  } else col += amb(reflect(rd, n))*fr*occ*min(m.spec, 1.0)*1.5;
  gRefl = id > 0.5 ? m.refl*(0.04 + 0.96*fr)*occ : 0.0; gN = n;
  return col;
}

vec3 beam(vec3 ro, vec3 rd, vec3 s, vec3 tg, float tm){
  vec3 D = normalize(tg - s), w = ro - s;
  float b = dot(rd, D), d = dot(rd, w), e = dot(D, w), den = max(1.0 - b*b, 1e-4);
  float u = clamp((e - b*d)/den, 0.0, 14.0), v = max((b*e - d)/den, 0.0);
  if (v > tm) return vec3(0.0);
  float r = length(ro + rd*v - s - D*u), wd = 0.06 + 0.1*u;
  return beamC*exp(-r*r/(wd*wd))*exp(-u*0.12)*0.08;
}
// light scattered toward the eye by the mist around a point lamp, along a ray of length tm
float scat(vec3 ro, vec3 rd, vec3 lp, float tm){
  vec3 q = ro - lp; float b = dot(rd, q), h = sqrt(max(dot(q, q) - b*b, 0.0) + 0.12);
  return (atan((tm + b)/h) - atan(b/h))/h;
}

vec3 render(vec3 ro0, vec3 rd0){
  vec3 ro, ta; float roll, fl;
  direct(iTime + T0, ro, ta, roll, fl);
  vec2 uv = (2.0*gl_FragCoord.xy - iResolution)/min(iResolution.x, iResolution.y);
  uv = rot(roll)*uv;
  vec3 f = normalize(ta - ro), r = normalize(cross(vec3(0.0, 1.0, 0.0), f)), u = cross(f, r);
  vec3 rd = normalize(uv.x*r + uv.y*u + fl*f);
  float t = marchT(ro, rd, FAR, uSteps), tm = t < 0.0 ? FAR : t;
  vec3 col;
  if (t < 0.0) col = sky(rd);
  else {
    col = surf(ro, rd, t, true);
    if (gRefl > 0.01){
      // wet rock and puddles mirror the stage
      float k = gRefl; vec3 p = ro + rd*t + gN*0.02, rr = reflect(rd, gN);
      float t2 = marchT(p, rr, 40.0, 90);
      col += k*(t2 < 0.0 ? sky(rr) : mix(surf(p, rr, t2, false), fogCol(), 1.0 - exp(-gFog*t2)));
    }
    col = mix(col, t > 150.0 ? sky(rd) : fogCol(), 1.0 - exp(-gFog*t*(1.0 + 0.0*rain)));
  }
  // mist: the cross, the flower and the lamps glow in it
  float mist = 0.35 + 0.65*rain + 4.0*hit(T, 106.3, 1.0, 0.5);
  col += GOLD*crossI*0.02*mist*(0.3 + 0.7*(1.0 - veins))*scat(ro, rd, LC + vec3(0.0, 0.0, 0.5), tm);
  col += vec3(1.0, 0.3, 0.5)*bloom*bloom*fsc*0.006*mist*scat(ro, rd, FB + vec3(0.0, 1.3*fsc, 0.0), tm);
  for (int i = 0; i < 4; i++){
    float fi = float(i), sx = i < 2 ? -1.0 : 1.0, sz = mod(fi, 2.0) < 0.5 ? 4.37 : -3.37;
    vec3 lp = vec3(5.8*sx, 6.14, sz), tg = vec3(2.5*sin(T*0.9 + fi*1.7), 0.0, 1.0 + 2.5*cos(T*0.7 + fi*2.3));
    vec3 lc = sz > 0.0 ? beamC*beamI*(1.0 + pul) + vec3(0.5, 0.62, 1.0)*0.08*spotI : vec3(1.0, 0.85, 0.7)*spotI*0.25;
    if (beamI > 0.0) col += beam(ro, rd, lp, tg, tm)*beamI*(1.0 + pul)*(sz > 0.0 ? 1.0 : 0.45);
    col += lc*0.0035*mist*scat(ro, rd, lp, tm);
  }
  // the cross's halo and its rays through the rain, when it faces the camera
  if (ro.z < 6.7){
    vec3 cp = vec3(0.0, 3.6, 6.8) - ro;
    float z = dot(cp, f);
    if (z > 0.0){
      vec2 c = vec2(dot(cp, r), dot(cp, u))/z*fl, q = uv - c;
      float sc = fl/z, k = min(sdBox(vec3(q, 0.0), vec3(0.75, 3.6, 0.0)*sc), sdBox(vec3(q - vec2(0.0, 1.1*sc), 0.0), vec3(2.4, 0.75, 0.0)*sc));
      float vis = tm > z - 1.0 ? 1.0 : 0.3;
      col += GOLD*crossI*0.05*min(sc, 0.5)/(max(k, 0.0)/sc*1.6 + 0.2)*vis*(1.0 - 0.75*veins*step(k, 0.0));
      vec2 qc = q - vec2(0.0, 1.1*sc);
      float an = atan(qc.y, qc.x), ray = pow(noise(vec2(an*9.0, T*0.4)), 2.0)*0.7 + pow(noise(vec2(an*23.0 + 4.0, T*0.7)), 3.0);
      col += GOLD*crossI*0.03*ray*min(sc, 0.5)/(length(qc)/sc*0.5 + 0.5)*(0.4 + 0.6*rain);
    }
  }
  // rain: three layers, the near one thick and fast
  float rr = 0.0;
  for (int i = 0; i < 3; i++){
    float fi = float(i);
    vec2 q = uv*vec2(13.0 + fi*17.0, 1.6 + fi*0.9);
    q.x += q.y*(0.3 + 0.06*fi)*wind*(4.0 - fi)*0.33;
    q.y += T*(9.0 - fi*1.6);
    vec2 id = floor(q), fq = fract(q);
    rr += step(0.86 - 0.03*fi, hash(id + fi*17.0))*ease(0.1 + 0.03*fi, 0.0, abs(fq.x - 0.5))*fq.y*(0.25 + 0.2*fi)*(tm > 2.0 + 6.0*fi ? 1.0 : 0.3);
  }
  col += vec3(0.55, 0.6, 0.7)*rr*rain*0.1*(1.0 + 3.0*lit + beamI + 1.5*crossI*0.3);
  // the grade
  col *= gTint*1.15;
  col = col*(1.0 + col*0.12)/(1.0 + col*0.55);
  col = mix(vec3(dot(col, vec3(0.3, 0.6, 0.1))), col, 1.12 + 0.25*drop);
  col += (hash(gl_FragCoord.xy*0.37 + fract(T*7.3)*91.0) - 0.5)*0.012;
  col += vec3(whiteout);
  return max(col, 0.0)*fade;
}
