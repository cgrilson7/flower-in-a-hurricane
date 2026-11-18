// The shader around the scene: uniforms, the small helper library flower.glsl relies on, and main().
// flower.glsl defines render(), which does everything else (camera, march, light, grade).
const HELPERS = `
#define PI 3.14159265
float hash(float n){ return fract(sin(n)*43758.5453123); }
float hash(vec2 p){ p = fract(p*vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x*p.y); }
float hash(vec3 p){ p = fract(p*0.3183099 + 0.1); p *= 17.0; return fract(p.x*p.y*p.z*(p.x + p.y + p.z)); }
float noise(vec2 x){ vec2 i = floor(x), f = fract(x); f = f*f*(3.0 - 2.0*f);
  return mix(mix(hash(i), hash(i + vec2(1,0)), f.x), mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x), f.y); }
float noise(vec3 x){ vec3 i = floor(x), f = fract(x); f = f*f*(3.0 - 2.0*f);
  return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
             mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z); }
float fbm(vec2 p){ float s = 0.0, a = 0.5; mat2 m = mat2(1.6, 1.2, -1.2, 1.6); for (int i = 0; i < 5; i++){ s += a*noise(p); p = m*p; a *= 0.5; } return s; }
float fbm(vec3 p){ float s = 0.0, a = 0.5; for (int i = 0; i < 5; i++){ s += a*noise(p); p = p*2.02 + vec3(1.7, 9.2, 3.1); a *= 0.5; } return s; }
mat2 rot(float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }
float smin(float a, float b, float k){ float h = clamp(0.5 + 0.5*(b - a)/k, 0.0, 1.0); return mix(b, a, h) - k*h*(1.0 - h); }
float smax(float a, float b, float k){ return -smin(-a, -b, k); }
float sdSphere(vec3 p, float r){ return length(p) - r; }
float sdBox(vec3 p, vec3 b){ vec3 q = abs(p) - b; return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0); }
float sdTorus(vec3 p, vec2 t){ return length(vec2(length(p.xz) - t.x, p.y)) - t.y; }
float sdCapsule(vec3 p, vec3 a, vec3 b, float r){ vec3 pa = p - a, ba = b - a; float h = clamp(dot(pa, ba)/dot(ba, ba), 0.0, 1.0); return length(pa - ba*h) - r; }
float sdCylinder(vec3 p, float r, float h){ vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h); return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)); }
vec3 pal(float t, vec3 a, vec3 b, vec3 c, vec3 d){ return a + b*cos(6.28318*(c*t + d)); }
`
exports.build = (src) => `#version 300 es
precision highp float;
precision highp int;
uniform vec2 iResolution;
uniform float iTime;
uniform int uSteps;
out vec4 fragColor;
${HELPERS}
#line 1
${src}
#line 10000
void main(){
  vec3 col = render(vec3(0.0), vec3(0.0, 0.0, 1.0));
  col = pow(clamp(col, 0.0, 1.0), vec3(0.4545));
  vec2 q = gl_FragCoord.xy/iResolution;
  col *= 0.5 + 0.5*pow(16.0*q.x*q.y*(1.0 - q.x)*(1.0 - q.y), 0.15);
  fragColor = vec4(col, 1.0);
}
`
