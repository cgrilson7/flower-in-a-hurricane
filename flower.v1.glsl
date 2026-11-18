// @title Flower in a hurricane
// @spawn 0 2 -9 0
// @speed 2
// A music video, cut to the song: T is the song's second (iTime + T0). 126 BPM, beats on multiples of 0.4762 s.
#define T0 0.0
#define FAR 220.0
#define FOG gFog
#define SUN normalize(vec3(-0.35, 0.55, -0.75))
#define SUNCOL gSun

const float BEAT = 0.476190, BAR = 1.904762;
const vec3 PM = vec3(-2.3, 0.0, 0.3), PF = vec3(2.3, 0.0, 0.3), PA = vec3(-0.72, 0.0, 3.25), PB = vec3(0.72, 0.0, 3.25);
const vec3 FB = vec3(0.0, 0.0, -2.0);

float T = 0.0, pul = 0.0, gFog = 0.012, crossI = 0.0, beamI = 0.0, lit = 0.0, rain = 1.0, wave = 1.0, wind = 1.0;
float bloom = 0.0, fsc = 1.0, dawn = 0.0, fade = 1.0, whiteout = 0.0, spotI = 0.0, ring = 1e3, gid = 0.0, boltA = 0.0;
vec3 gSun = vec3(0.08, 0.09, 0.14), beamC = vec3(1.0);

float ease(float a, float b, float x){ return smoothstep(a, b, x); }
float hit(float t, float at, float amp, float k){ return t < at ? 0.0 : amp*exp(-(t - at)*k); }
float sdEll(vec3 p, vec3 r){ float k0 = length(p/r), k1 = length(p/(r*r)); return k0*(k0 - 1.0)/k1; }
void U(inout float d, float k, float id){ if (k < d){ d = k; gid = id; } }
float limb(vec3 q, vec3 a, vec3 b, vec3 c, float r){ return min(sdCapsule(q, a, b, r), sdCapsule(q, b, c, r*0.85)); }
float curls(vec3 q, float f){ return sin(q.x*f)*sin(q.y*f*0.95)*sin(q.z*f*1.05); }

// the guitarist and male vocalist: long straight hair, beard, white tee, cream guitar, at a mic stand
float male(vec3 q){
  float d = 1e3, k;
  q.x -= 0.03*sin(T*1.9)*q.y;
  k = min(sdCapsule(q, vec3(-0.11, 0.06, 0.0), vec3(-0.1, 0.86, 0.0), 0.075), sdCapsule(q, vec3(0.11, 0.06, 0.0), vec3(0.1, 0.86, 0.0), 0.075));
  U(d, k, 21.0);
  q.y -= 0.015*pul;
  U(d, sdBox(q - vec3(0.0, 1.13, 0.0), vec3(0.13, 0.24, 0.075)) - 0.05, 20.0);
  k = min(sdSphere(q - vec3(0.0, 1.62, -0.01), 0.105), sdCapsule(q, vec3(0.0, 1.4, 0.0), vec3(0.0, 1.55, 0.0), 0.05));
  U(d, k, 10.0);
  U(d, sdEll(q - vec3(0.0, 1.55, -0.055), vec3(0.08, 0.075, 0.06)), 15.0);
  vec3 h = vec3(abs(q.x) - 0.095, q.y - 1.5, q.z - 0.025);
  k = min(sdBox(h, vec3(0.025, 0.15, 0.07)) - 0.015, sdBox(q - vec3(0.0, 1.5, 0.08), vec3(0.11, 0.16, 0.03)) - 0.015);
  k = smin(k, sdSphere(q - vec3(0.0, 1.655, 0.02), 0.112), 0.05);
  U(d, k, 11.0);
  U(d, sdSphere(vec3(abs(q.x) - 0.036, q.y - 1.632, q.z + 0.1), 0.014), 14.0);
  // guitar, slung across, neck up to his left (+x)
  vec3 g = q - vec3(0.0, 0.98, -0.15);
  g.xy = rot(-0.45)*g.xy;
  float gb = smin(length(g.xy - vec2(-0.06, 0.0)) - 0.17, length(g.xy - vec2(0.1, 0.03)) - 0.13, 0.08);
  U(d, max(gb, abs(g.z) - 0.035), 25.0);
  U(d, min(sdBox(g - vec3(0.42, 0.04, 0.0), vec3(0.25, 0.025, 0.018)), sdBox(g - vec3(0.72, 0.04, 0.0), vec3(0.06, 0.04, 0.015))), 26.0);
  float s = 0.04*sin(T*6.2832/(BEAT*0.5));
  vec3 fr = vec3(0.0, 0.98, -0.19) + vec3(rot(0.45)*vec2(0.5, 0.06), 0.0);
  vec3 sh = vec3(-0.19, 1.37, 0.0), sh2 = vec3(0.19, 1.37, 0.0);
  U(d, min(sdCapsule(q, sh, vec3(-0.26, 1.12, -0.04), 0.06), sdCapsule(q, sh2, vec3(0.29, 1.12, -0.08), 0.06)), 20.0);
  k = min(sdCapsule(q, vec3(-0.26, 1.12, -0.04), vec3(-0.03, 1.0 + s, -0.22), 0.045), sdCapsule(q, vec3(0.29, 1.12, -0.08), fr, 0.045));
  U(d, k, 10.0);
  // mic stand
  k = min(sdCapsule(q, vec3(0.0, 0.0, -0.45), vec3(0.0, 1.35, -0.45), 0.015), sdCapsule(q, vec3(0.0, 1.35, -0.45), vec3(0.0, 1.52, -0.22), 0.012));
  k = min(k, sdCapsule(q, vec3(0.0, 1.53, -0.24), vec3(0.0, 1.565, -0.17), 0.025));
  U(d, min(k, sdCylinder(q - vec3(0.0, 0.01, -0.45), 0.18, 0.01)), 27.0);
  return d;
}

// the female vocalist: big curly red hair, oversized pinstripe jacket and trousers, handheld mic
float female(vec3 q){
  float d = 1e3, k;
  q.x -= 0.04*sin(T*1.6 + 1.0)*q.y;
  k = min(sdCapsule(q, vec3(-0.12, 0.06, 0.0), vec3(-0.11, 0.86, 0.0), 0.105), sdCapsule(q, vec3(0.12, 0.06, 0.0), vec3(0.11, 0.86, 0.0), 0.105));
  U(d, k, 22.0);
  q.y -= 0.02*pul;
  U(d, sdBox(q - vec3(0.0, 1.12, 0.0), vec3(0.19, 0.26, 0.1)) - 0.06, 22.0);
  k = min(sdSphere(q - vec3(0.0, 1.62, 0.0), 0.1), sdCapsule(q, vec3(0.0, 1.42, 0.0), vec3(0.0, 1.55, 0.0), 0.045));
  U(d, k, 10.0);
  vec3 h = q - vec3(0.0, 1.5, 0.14);
  h.x -= 0.05*wind*sin(T*2.7)*(1.86 - q.y);
  k = sdEll(h, vec3(0.27, 0.36, 0.2)) + 0.025*curls(h, 42.0);
  k = max(k, -sdEll(q - vec3(0.0, 1.57, -0.16), vec3(0.13, 0.2, 0.2)));
  U(d, k*0.8, 12.0);
  U(d, sdSphere(vec3(abs(q.x) - 0.034, q.y - 1.635, q.z + 0.09), 0.013), 14.0);
  float g = 0.05*sin(T*6.2832/(BEAT*2.0));
  vec3 hr = vec3(-0.07, 1.5, -0.16), hl = vec3(0.1 + g, 1.25 + g, -0.26);
  k = min(limb(q, vec3(-0.24, 1.37, 0.0), vec3(-0.23, 1.12, -0.17), hr, 0.075), limb(q, vec3(0.24, 1.37, 0.0), vec3(0.31, 1.12, -0.1), hl, 0.075));
  U(d, k, 22.0);
  U(d, min(sdSphere(q - hr, 0.045), sdSphere(q - hl, 0.04)), 10.0);
  U(d, sdCapsule(q, hr + vec3(0.01, -0.03, 0.0), vec3(0.0, 1.585, -0.13), 0.026), 27.0);
  return d;
}

// a DJ behind the booth (only the upper body shows): w 0 curly hair and beard, w 1 dark hair and varsity jacket
float dj(vec3 q, float w){
  float d = 1e3, k;
  q.y -= 0.02*pul;
  vec3 b = q - vec3(0.0, 0.9, 0.0);
  b.yz = rot(-0.18)*b.yz;
  q = b + vec3(0.0, 0.9, 0.0);
  U(d, sdBox(q - vec3(0.0, 1.15, 0.0), vec3(0.15, 0.24, 0.09)) - 0.06, 23.0 + w);
  vec3 hq = q - vec3(0.0, 1.45, 0.0);
  hq.yz = rot(-0.2 - 0.25*pul)*hq.yz;
  hq += vec3(0.0, 1.45, 0.0);
  k = min(sdSphere(hq - vec3(0.0, 1.6, -0.02), 0.105), sdCapsule(q, vec3(0.0, 1.38, 0.0), vec3(0.0, 1.5, 0.0), 0.05));
  U(d, k, 10.0);
  if (w < 0.5){
    k = sdSphere(hq - vec3(0.0, 1.67, 0.02), 0.16) + 0.02*curls(hq, 50.0);
    U(d, max(k*0.8, -sdEll(hq - vec3(0.0, 1.56, -0.14), vec3(0.1, 0.12, 0.12))), 13.0);
    U(d, sdEll(hq - vec3(0.0, 1.53, -0.06), vec3(0.08, 0.07, 0.06)), 15.0);
  } else {
    U(d, max(sdSphere(hq - vec3(0.0, 1.64, 0.0), 0.118), -sdEll(hq - vec3(0.0, 1.56, -0.13), vec3(0.1, 0.11, 0.1))), 14.0);
  }
  U(d, sdSphere(vec3(abs(hq.x) - 0.036, hq.y - 1.615, hq.z + 0.115), 0.014), 14.0);
  float m = 0.05*sin(T*6.2832/BEAT + w*2.0);
  k = min(limb(q, vec3(-0.22, 1.33, -0.02), vec3(-0.28, 1.1, -0.22), vec3(-0.2 + m, 1.06, -0.42), 0.065),
          limb(q, vec3(0.22, 1.33, -0.02), vec3(0.28, 1.1, -0.22), vec3(0.2 - m*w, 1.06, -0.42), 0.065));
  U(d, k, 23.0 + w);
  return d;
}

// the flower, base at the origin; it blooms with `bloom` and grows with `fsc`
float flower(vec3 q){
  float d = 1e3, k;
  q /= fsc;
  q.x -= (0.12*wind + 0.06*wind*sin(T*3.1))*q.y*q.y;
  const float H = 1.25;
  U(d, sdCapsule(q, vec3(0.0), vec3(0.0, H, 0.0), 0.022), 32.0);
  vec3 l = vec3(abs(q.x) - 0.13, q.y - 0.45 - 0.15*step(0.0, q.x), q.z);
  l.xy = rot(0.5)*l.xy;
  U(d, sdEll(l, vec3(0.14, 0.03, 0.06)), 32.0);
  vec3 c = q - vec3(0.0, H, 0.0);
  c.yz = rot(-0.7)*c.yz;
  U(d, sdSphere(c, 0.07 + 0.03*bloom), 31.0);
  float a = atan(c.y, c.x), r = length(c.xy), sec = 6.2832/7.0;
  float i = floor(a/sec + 0.5), aa = a - i*sec;
  vec2 pl = vec2(cos(aa), sin(aa))*r;
  float L = 0.1 + 0.2*bloom;
  vec3 pp = vec3(pl.x - 0.05 - L, pl.y, c.z + (1.0 - bloom)*pl.x*1.4 - 0.25*bloom*pl.x*pl.x + 0.03*wind*sin(T*9.0 + i*1.7)*pl.x);
  U(d, sdEll(pp, vec3(L, 0.07 + 0.05*bloom, 0.018))*0.5, 30.0);
  return d*fsc;
}

float sea(vec2 xz){
  float r = length(xz);
  float h = wave*(0.45*sin(xz.x*0.21 + T*1.3) + 0.45*sin(xz.y*0.17 - T*1.1 + xz.x*0.1)) + 0.6*wave*noise(xz*0.35 + T*0.5);
  return h + 4.0*exp(-(r - ring)*(r - ring)*0.02) - 4.0;
}

float scene(vec3 p){
  gid = 0.0;
  float d = (p.y - sea(p.xz))*0.5, k;
  k = sdCylinder(p - vec3(0.0, -3.4, 0.5), 7.3, 3.0) + 0.6*noise(p*0.9) - 0.3;
  U(d, k*0.7, 1.0);
  U(d, sdCylinder(p - vec3(0.0, -0.12, 0.5), 7.1, 0.12), 2.0);
  vec3 tq = vec3(abs(p.x) - 6.0, p.y, abs(p.z - 0.5) - 4.0);
  k = min(sdCapsule(tq, vec3(0.0), vec3(0.0, 6.0, 0.0), 0.1), sdCapsule(vec3(abs(p.x), p.y - 6.0, tq.z), vec3(0.0), vec3(6.0, 0.0, 0.0), 0.08));
  k = min(k, sdBox(vec3(abs(p.x) - 5.4, p.y - 5.8, tq.z), vec3(0.16)));
  U(d, k, 3.0);
  // the booth: road cases, the decks and keys, and the cross on its front
  if (length(p - vec3(0.0, 0.8, 2.6)) < 2.6){
    U(d, sdBox(p - vec3(0.0, 0.5, 2.65), vec3(1.9, 0.5, 0.42)), 4.0);
    U(d, min(sdBox(p - vec3(-0.7, 1.04, 2.62), vec3(0.45, 0.04, 0.3)), sdBox(p - vec3(0.7, 1.06, 2.62), vec3(0.5, 0.05, 0.22))), 6.0);
    U(d, min(sdBox(p - vec3(0.0, 0.72, 2.17), vec3(0.17, 0.7, 0.05)), sdBox(p - vec3(0.0, 0.9, 2.17), vec3(0.52, 0.17, 0.05))), 5.0);
  } else U(d, length(p - vec3(0.0, 0.8, 2.6)) - 2.5, 4.0);
  float sg = gid, kk;
  k = length(p - PA - vec3(0.0, 1.3, 0.0)) - 0.8;
  if (k < d){ if (k < 0.1){ kk = dj(p - PA, 0.0); if (kk < d){ d = kk; sg = gid; } } else { d = k; sg = 23.0; } }
  k = length(p - PB - vec3(0.0, 1.3, 0.0)) - 0.8;
  if (k < d){ if (k < 0.1){ kk = dj(p - PB, 1.0); if (kk < d){ d = kk; sg = gid; } } else { d = k; sg = 24.0; } }
  k = length(p - PM - vec3(0.0, 0.95, 0.0)) - 1.2;
  if (k < d){ if (k < 0.1){ kk = male(p - PM); if (kk < d){ d = kk; sg = gid; } } else { d = k; sg = 20.0; } }
  k = length(p - PF - vec3(0.0, 0.95, 0.0)) - 1.15;
  if (k < d){ if (k < 0.1){ kk = female(p - PF); if (kk < d){ d = kk; sg = gid; } } else { d = k; sg = 22.0; } }
  k = length(p - FB - vec3(0.0, 0.8, 0.0)*fsc) - 1.1*fsc;
  if (k < d){ if (k < 0.1){ kk = flower(p - FB); if (kk < d){ d = kk; sg = gid; } } else { d = k; sg = 32.0; } }
  gid = sg;
  return d;
}
float map(vec3 p){ return scene(p); }

// the timeline: what is on screen at second t, and the camera
vec3 orbit(vec3 c, float r, float h, float a){ return c + vec3(sin(a)*r, h, -cos(a)*r); }
void dropShot(float t, float t0, out vec3 ro, out vec3 ta){
  float i = mod(floor((t - t0)/(BAR*2.0)), 5.0), u = mod(t - t0, BAR*2.0);
  if (i < 0.5){ ro = vec3(-14.0 + u, 1.0, -16.0 + u); ta = vec3(0.0, 1.8, 2.0); }
  else if (i < 1.5){ ro = PA + vec3(-0.9 + 0.1*u, 1.6, -1.6); ta = PA + vec3(0.0, 1.45, 0.0); }
  else if (i < 2.5){ ro = PB + vec3(0.9 - 0.1*u, 1.6, -1.6); ta = PB + vec3(0.0, 1.4, 0.0); }
  else if (i < 3.5){ ro = vec3(0.0, 2.2 + 0.2*u, 5.4); ta = vec3(0.0, 1.0, -3.0); }
  else { ro = vec3(0.6 - 0.3*u, 0.5, -1.0); ta = vec3(0.0, 1.2, 2.2); }
}

void direct(float t, out vec3 ro, out vec3 ta, out float roll, out float fl){
  T = t; roll = 0.0; fl = 1.7;
  float drum = (t > 33.2 && t < 35.2) || (t > 42.0 && t < 42.9) || (t > 47.7 && t < 141.5) || (t > 150.0 && t < 157.1) || (t > 162.95 && t < 209.5) ? 1.0 : 0.0;
  pul = drum*exp(-fract(t/BEAT)*6.0);
  float barN = floor(t/BAR);
  dawn = ease(209.5, 221.0, t);
  // light
  crossI = (t < 33.2 ? 0.0 : 1.0)*(0.5 + 1.2*pul) + hit(t, 33.22, 4.0, 2.0) + hit(t, 42.02, 3.0, 3.0) + hit(t, 162.97, 5.0, 1.5);
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
  else if (t < 101.0){ float s = ease(94.0, 101.0, t); ro = mix(vec3(-18.0, 0.5, -22.0), vec3(-11.0, 1.2, -14.0), s); ta = vec3(0.0, 2.5, 0.0); }
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
  else if (t < 162.97){ float s = ease(159.25, 162.97, t); ro = mix(vec3(0.0, 1.3, 6.0), vec3(0.0, 6.0, 9.0), s); ta = vec3(0.0, 1.0, -2.0); }
  else if (t < 164.88){ ro = vec3(0.0, 0.6, -7.5); ta = vec3(0.0, 2.0, 0.0); }
  else if (t < 168.45){ ro = PF + vec3(-0.5, 1.5, -1.8); ta = PF + vec3(0.0, 1.5, 0.0); }
  else if (t < 172.14){ ro = PM + vec3(0.5, 1.5, -1.8); ta = PM + vec3(0.0, 1.45, 0.0); }
  else if (t < 175.0){ ro = orbit(FB, 3.0, 0.3, -0.3 + 0.2*(t - 172.14)); ta = fh; }
  else if (t < 178.4){ ro = orbit(vec3(0.0, 0.0, 0.3), 4.5, 1.4, -0.4 + 0.25*(t - 175.0)); ta = vec3(0.0, 1.3, 0.3); }
  else if (t < 180.3){ ro = PA + vec3(-0.9, 1.6, -1.6); ta = PA + vec3(0.0, 1.45, 0.0); }
  else if (t < 182.2){ ro = PB + vec3(0.9, 1.6, -1.6); ta = PB + vec3(0.0, 1.4, 0.0); }
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
}

vec3 sky(vec3 rd){
  float a = atan(rd.z, rd.x), e = rd.y;
  vec3 c = mix(vec3(0.02, 0.025, 0.04), vec3(0.004, 0.006, 0.015), clamp(e, 0.0, 1.0));
  vec3 s = floor(rd*300.0);
  c += step(0.998, hash(s))*ease(0.5, 0.8, e)*0.6*(1.0 - dawn);
  float sp = a + 2.5*log(1.0 + max(e, 0.0)*4.0) - T*0.06;
  float cl = fbm(vec3(cos(sp)*2.0, sin(sp)*2.0, e*5.0 + T*0.04));
  float wall = 1.0 - ease(0.2, 0.62 + 0.3*dawn, e);
  vec3 cc = vec3(0.035, 0.04, 0.055)*(0.6 + cl) + lit*vec3(0.5, 0.55, 0.8)*(0.3 + cl);
  c = mix(c, cc, clamp(wall*(0.4 + cl)*1.2, 0.0, 1.0)*(1.0 - 0.6*dawn));
  c += beamC*0.05*exp(-abs(e)*7.0)*beamI;
  float dx = atan(sin(a - boltA), cos(a - boltA)) + 0.05*(noise(vec2(e*14.0, boltA)) - 0.5) + 0.02*(noise(vec2(e*50.0, boltA)) - 0.5);
  c += vec3(0.8, 0.85, 1.0)*ease(0.008, 0.0, abs(dx))*step(0.0, e)*step(e, 0.5)*lit*3.0;
  vec3 sd = normalize(vec3(0.2, 0.04, -1.0));
  vec3 dc = mix(vec3(1.0, 0.5, 0.25), vec3(0.25, 0.4, 0.7), clamp(e*2.5, 0.0, 1.0))*(0.6 + 0.4*cl);
  dc += vec3(1.0, 0.7, 0.35)*(pow(max(dot(rd, sd), 0.0), 400.0)*6.0 + pow(max(dot(rd, sd), 0.0), 8.0)*0.6);
  return mix(c, dc, dawn);
}

vec3 material(vec3 p, vec3 n){
  scene(p);
  float id = gid;
  if (id < 0.5) return vec3(0.01, 0.02, 0.03) + vec3(0.25)*ease(0.6, 1.4, p.y + 4.0 - 0.0)*0.3;
  if (id < 1.5) return vec3(0.06, 0.055, 0.05)*(0.6 + 0.8*noise(p*3.0));
  if (id < 2.5) return vec3(0.04)*(0.8 + 0.4*step(0.5, fract(length(p.xz - vec2(0.0, 0.5))*1.5)));
  if (id < 3.5) return vec3(0.25);
  if (id < 4.5){ vec3 q = abs(p - vec3(0.0, 0.5, 2.65)) - vec3(1.9, 0.5, 0.42); float e = min(min(max(q.x, q.y), max(q.y, q.z)), max(q.x, q.z)); return e > -0.04 ? vec3(0.4) : vec3(0.012); }
  if (id < 5.5) return vec3(0.9);
  if (id < 6.5) return vec3(0.03);
  if (id < 10.5) return vec3(0.5, 0.3, 0.22);
  if (id < 11.5) return vec3(0.11, 0.065, 0.03);
  if (id < 12.5) return vec3(0.45, 0.06, 0.03);
  if (id < 13.5) return vec3(0.08, 0.05, 0.03);
  if (id < 14.5) return vec3(0.015);
  if (id < 15.5) return vec3(0.12, 0.07, 0.04);
  if (id < 20.5) return vec3(0.75);
  if (id < 21.5) return vec3(0.03, 0.04, 0.07);
  if (id < 22.5) return mix(vec3(0.12, 0.13, 0.15), vec3(0.4), step(0.75, fract(atan(p.z - PF.z, p.x - PF.x)*9.0)));
  if (id < 23.5) return vec3(0.04, 0.05, 0.04);
  if (id < 24.5){ vec3 q = p - PB; float txt = step(abs(q.y - 1.28), 0.05)*step(abs(q.x), 0.12)*step(0.4, hash(floor(vec2(q.x*40.0, q.y*30.0)))); return mix(vec3(0.012), vec3(0.8), txt); }
  if (id < 25.5) return vec3(0.7, 0.6, 0.42);
  if (id < 26.5) return vec3(0.3, 0.18, 0.08);
  if (id < 27.5) return vec3(0.02);
  if (id < 30.5) return vec3(0.9, 0.2, 0.35);
  if (id < 31.5) return vec3(0.9, 0.6, 0.05);
  return vec3(0.05, 0.2, 0.04);
}

vec3 pl(vec3 p, vec3 n, vec3 alb, vec3 lp, vec3 c, float k){
  vec3 l = lp - p; float dd = dot(l, l);
  return alb*c*max(dot(n, l*inversesqrt(dd)), 0.0)*k/(1.0 + dd);
}

vec3 glow(vec3 p, vec3 n){
  vec3 alb = material(p, n), g = vec3(0.0);
  float id = gid;
  g += pl(p, n, alb, vec3(0.0, 0.85, 1.9), vec3(1.0, 0.97, 0.92), crossI*6.0);
  g += pl(p, n, alb, vec3(-2.3, 4.0, -2.5), vec3(1.0, 0.85, 0.7), spotI*30.0);
  g += pl(p, n, alb, vec3(2.3, 4.0, -2.5), vec3(1.0, 0.85, 0.7), spotI*30.0);
  g += pl(p, n, alb, vec3(0.0, 3.2, 4.2), beamC, beamI*(14.0 + 14.0*pul));
  g += pl(p, n, alb, FB + vec3(0.0, 1.3*fsc, -0.3), vec3(1.0, 0.3, 0.5), bloom*bloom*4.0*fsc);
  if (id > 4.5 && id < 5.5) g += vec3(1.0, 0.97, 0.92)*crossI*2.0;
  if (id > 2.5 && id < 3.5 && p.y > 5.6 && p.y < 5.98 && abs(abs(p.x) - 5.4) < 0.18) g += beamC*beamI*3.0;
  if (id > 29.5 && id < 31.5) g += (id < 30.5 ? vec3(1.0, 0.25, 0.45) : vec3(1.0, 0.7, 0.1))*(0.05 + 0.5*bloom*(0.7 + 0.3*pul));
  if (id < 0.5) g += vec3(0.6, 0.7, 0.8)*ease(0.9, 1.5, p.y - sea(p.xz) + 4.0 + sea(p.xz) - 0.0)*0.0;
  return g;
}

vec3 shade(vec3 ro, vec3 rd);

vec3 beam(vec3 ro, vec3 rd, vec3 s, vec3 tg){
  vec3 D = normalize(tg - s), w = ro - s;
  float b = dot(rd, D), d = dot(rd, w), e = dot(D, w), den = max(1.0 - b*b, 1e-4);
  float u = clamp((e - b*d)/den, 0.0, 14.0), v = max((b*e - d)/den, 0.0);
  float r = length(ro + rd*v - s - D*u), wd = 0.06 + 0.1*u;
  return beamC*exp(-r*r/(wd*wd))*exp(-u*0.12)*0.12;
}

vec3 render(vec3 ro0, vec3 rd0){
  vec3 ro, ta; float roll, fl;
  direct(iTime + T0, ro, ta, roll, fl);
  vec2 uv = (2.0*gl_FragCoord.xy - iResolution)/min(iResolution.x, iResolution.y);
  uv = rot(roll)*uv;
  vec3 f = normalize(ta - ro), r = normalize(cross(vec3(0.0, 1.0, 0.0), f)), u = cross(f, r);
  vec3 rd = normalize(uv.x*r + uv.y*u + fl*f);
  vec3 col = shade(ro, rd);
  if (beamI > 0.0){
    vec3 bm = vec3(0.0);
    for (int i = 0; i < 4; i++){
      float fi = float(i), sx = i < 2 ? -1.0 : 1.0, sz = mod(fi, 2.0) < 0.5 ? 4.5 : -3.5;
      vec3 tg = vec3(2.5*sin(T*0.9 + fi*1.7), 0.0, 1.0 + 2.5*cos(T*0.7 + fi*2.3));
      bm += beam(ro, rd, vec3(5.4*sx, 5.75, sz), tg);
    }
    col += bm*beamI*(1.0 + pul);
  }
  // the cross's halo, when it faces the camera
  if (ro.z < 2.1){
    vec3 cp = vec3(0.0, 0.85, 2.17) - ro;
    float z = dot(cp, f);
    if (z > 0.0){
      vec2 c = vec2(dot(cp, r), dot(cp, u))/z*fl, q = uv - c;
      float sc = fl/z, k = min(sdBox(vec3(q, 0.0), vec3(0.17, 0.7, 0.0)*sc), sdBox(vec3(q - vec2(0.0, 0.05*sc), 0.0), vec3(0.52, 0.17, 0.0)*sc));
      col += vec3(1.0, 0.95, 0.9)*crossI*0.06*sc/(max(k, 0.0)/sc*6.0 + 0.15);
    }
  }
  // rain
  float rr = 0.0;
  for (int i = 0; i < 2; i++){
    float fi = float(i);
    vec2 q = uv*vec2(26.0 + fi*22.0, 2.5 + fi);
    q.x += q.y*0.35*wind;
    q.y += T*(7.0 + fi*4.0);
    vec2 id = floor(q), fq = fract(q);
    rr += step(0.82, hash(id + fi*17.0))*ease(0.12, 0.0, abs(fq.x - 0.5))*fq.y*(0.7 - fi*0.3);
  }
  col += vec3(0.55, 0.6, 0.7)*rr*rain*0.1*(1.0 + 3.0*lit + beamI);
  col += vec3(whiteout);
  return col*fade;
}
