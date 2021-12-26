#version 450
uniform samplerCube cubemap;
uniform samplerCube minmaxdepthmap;
uniform float dist;
uniform float exposure;
uniform float apfac;

in data
{
  vec2 sensorPos;
};

layout(location = 0) out vec4 col;
#define FLT_MAX 1e10
#define M_PI 3.141592653589793238
const float lambda = 0.550f;

//------------------------------------------------------------------------------
//---init.h---------------------------------------------------------------------
const float lens_outer_pupil_radius = 11.250000; // scene facing radius in mm
const float lens_inner_pupil_radius = 6.750000; // sensor facing radius in mm
const float lens_length = 82.800003; // overall lens length in mm
const float lens_focal_length = 37.500000; // approximate lens focal length in mm (BFL)
const float lens_aperture_pos = 22.949999; // distance aperture -> outer pupil in mm
const float lens_aperture_housing_radius = 7.500000; // lens housing radius at the aperture
const float lens_outer_pupil_curvature_radius = 39.675003; // radius of curvature of the outer pupil
const float lens_field_of_view = 0.946492; // cosine of the approximate field of view assuming a 35mm image
//------------------------------------------------------------------------------

void lens_sphereToCs(vec2 inpos, vec2 indir, out vec3 outpos, out vec3 outdir, float sphereCenter, float sphereRad)
{
  vec3 normal = vec3(inpos/sphereRad, sqrt(max(0.0f, sphereRad*sphereRad-dot(inpos, inpos)))/abs(sphereRad));
  vec3 tempDir = vec3(indir, sqrt(max(0.0f, 1.0f - dot(indir, indir))));

  vec3 ex = normalize(vec3(normal.z, 0, -normal.x));
  vec3 ey = cross(normal, ex);

  outdir = tempDir.x * ex + tempDir.y * ey + tempDir.z * normal;
  outpos = vec3(inpos, normal.z * sphereRad + sphereCenter);
}

float lens_ipow(const float a, const int exp)
{
  float ret = 1;
  for(int i = 0; i < exp; i++)
    ret *= a;
  return ret;
}

float eval(vec4 sensor, out vec4 outer)
{
  const float x = sensor.x+dist*sensor.p;
  const float y = sensor.y+dist*sensor.q;
  const float dx = sensor.p;
  const float dy = sensor.q;
//------------------------------------------------------------------------------
//---pt_evaluate.h--------------------------------------------------------------
const float out_x =  + 4.14156e-06  + 9.4601e-05 *dy + 63.788 *dx + 0.580638 *x + 0.00691194 *dx*dy + 0.00594115 *lens_ipow(dx, 2) + 3.54512e-05 *y*dy + 6.48931e-06 *y*dx + -2.53304e-06 *lens_ipow(x, 2) + -42.1458 *dx*lens_ipow(dy, 2) + -41.5653 *lens_ipow(dx, 3) + 0.0101871 *lens_ipow(y, 2)*dx + 0.402588 *x*lens_ipow(dy, 2) + 0.440775 *x*lens_ipow(dx, 2) + 0.027848 *x*y*dy + 0.000310157 *x*lens_ipow(y, 2) + -7.89401e-06 *lens_ipow(x, 2)*dy + 0.0389309 *lens_ipow(x, 2)*dx + 0.00031653 *lens_ipow(x, 3) + -0.167587 *dx*lens_ipow(dy, 3) + 0.10932 *x*lens_ipow(lambda, 3) + 5.43426e-05 *lens_ipow(x, 2)*lens_ipow(dy, 2) + 6.98847 *dx*lens_ipow(lambda, 4) + -13.4072 *lens_ipow(dx, 3)*lens_ipow(dy, 2) + -0.000341739 *lens_ipow(x, 2)*y*dx*dy + 2.87504e-05 *lens_ipow(x, 3)*lens_ipow(dy, 2) + 6.73182e-08 *lens_ipow(x, 3)*lens_ipow(y, 2) + 8.47988e-06 *lens_ipow(x, 3)*lens_ipow(lambda, 3) + -0.861698 *x*lens_ipow(dy, 6) + 0.0117886 *lens_ipow(x, 2)*lens_ipow(dx, 5) + -3.31667e-05 *lens_ipow(y, 4)*lens_ipow(dx, 5) + 6.70443e-08 *x*lens_ipow(y, 4)*lens_ipow(lambda, 4) + 3.11321e-09 *lens_ipow(x, 7)*lens_ipow(dy, 2)*lambda + -34.0239 *dx*lens_ipow(lambda, 10) + 73.4062 *lens_ipow(dx, 3)*lens_ipow(dy, 2)*lens_ipow(lambda, 6) + -4.85405 *lens_ipow(y, 2)*lens_ipow(dx, 9) + -0.58863 *x*lens_ipow(lambda, 10) + 10.5019 *lens_ipow(x, 2)*lens_ipow(dx, 7)*lens_ipow(dy, 2) + 1.2171e-15 *lens_ipow(x, 3)*lens_ipow(y, 8) + 1.94921e-16 *lens_ipow(x, 11);
const float out_y =  + 9.84161e-05  + 63.7892 *dy + -0.000241431 *dx + 0.580787 *y + -8.36848e-06 *x + -0.00215768 *lens_ipow(dy, 2) + 4.15993e-05 *x*dy + -7.87016e-07 *lens_ipow(x, 2) + -41.6097 *lens_ipow(dy, 3) + -42.3765 *lens_ipow(dx, 2)*dy + 0.442703 *y*lens_ipow(dy, 2) + 0.406335 *y*lens_ipow(dx, 2) + 0.0390684 *lens_ipow(y, 2)*dy + 0.00031502 *lens_ipow(y, 3) + 0.0280539 *x*y*dx + 2.18397e-07 *x*lens_ipow(y, 2) + 0.0101966 *lens_ipow(x, 2)*dy + 0.000313623 *lens_ipow(x, 2)*y + 0.107869 *y*lens_ipow(lambda, 3) + 2.88273e-05 *x*y*lens_ipow(dx, 2) + 6.99505 *dy*lens_ipow(lambda, 4) + 1.82742e-05 *lens_ipow(y, 3)*lens_ipow(lambda, 2) + -0.000291517 *x*lens_ipow(y, 2)*dx*dy + 0.000136205 *lens_ipow(x, 2)*y*lens_ipow(dy, 2) + -3.33188e-06 *lens_ipow(x, 3)*lens_ipow(dy, 2) + 0.000454737 *x*dx*dy*lens_ipow(lambda, 3) + -1.13346e-05 *x*lens_ipow(y, 2)*lens_ipow(dx, 3) + -1.30324 *y*lens_ipow(dx, 6) + 0.00721462 *lens_ipow(y, 2)*lens_ipow(dy, 5) + 0.00126761 *lens_ipow(y, 3)*lens_ipow(dx, 4) + -4.01598e-06 *x*lens_ipow(y, 3)*dx*lens_ipow(lambda, 2) + 4.23072e-09 *lens_ipow(x, 6)*dy*lambda + 5.3194e-14 *lens_ipow(y, 9) + 2.58734e-09 *lens_ipow(y, 7)*lens_ipow(dx, 2)*lambda + -34.2711 *dy*lens_ipow(lambda, 10) + -0.583891 *y*lens_ipow(lambda, 10) + 4.97323 *lens_ipow(y, 2)*lens_ipow(dx, 4)*lens_ipow(dy, 3)*lens_ipow(lambda, 2) + -0.000409019 *lens_ipow(y, 3)*lens_ipow(dy, 2)*lens_ipow(lambda, 6) + 3.73008e-15 *lens_ipow(x, 6)*lens_ipow(y, 5) + 7.46369e-13 *lens_ipow(x, 8)*y*lens_ipow(lambda, 2);
const float out_dx =  + 8.77934e-07  + -1.62653 *dx + 1.04461e-07 *y + -0.0305169 *x + -3.00388e-05 *dx*dy + -1.17129 *dx*lens_ipow(dy, 2) + 0.957525 *lens_ipow(dx, 3) + -0.0477567 *y*dx*dy + -0.000388176 *lens_ipow(y, 2)*dx + -0.0338663 *x*lens_ipow(dy, 2) + -0.00210107 *x*lens_ipow(dx, 2) + -0.00115822 *x*y*dy + -6.69569e-06 *x*lens_ipow(y, 2) + 3.72215e-07 *lens_ipow(x, 2)*dy + -0.000617968 *lens_ipow(x, 2)*dx + -3.23625e-06 *lens_ipow(x, 3) + 0.0256275 *dx*lens_ipow(lambda, 3) + -0.000656759 *x*lens_ipow(lambda, 3) + -2.59058e-10 *lens_ipow(x, 2)*lens_ipow(y, 2) + 1.69848 *lens_ipow(dx, 3)*lens_ipow(dy, 2) + 1.54598e-05 *lens_ipow(x, 2)*y*dx*dy + -4.32558e-09 *lens_ipow(x, 3)*lens_ipow(y, 2)*lambda + 8.41058 *dx*lens_ipow(dy, 6) + 0.00140868 *lens_ipow(y, 2)*lens_ipow(dx, 3)*lens_ipow(dy, 2) + -2.39971e-10 *lens_ipow(y, 6)*dx + -2.60479e-05 *lens_ipow(x, 3)*lens_ipow(dy, 4) + 0.00175003 *x*lens_ipow(lambda, 7) + -0.240983 *lens_ipow(dx, 3)*lens_ipow(lambda, 6) + 103.264 *lens_ipow(dx, 7)*lens_ipow(dy, 2) + 44.2151 *lens_ipow(dx, 9) + 5.44563e-05 *x*lens_ipow(y, 2)*lens_ipow(dx, 5)*dy + 0.000162603 *x*lens_ipow(y, 2)*lens_ipow(dx, 6) + -5.61238e-12 *lens_ipow(x, 7)*lens_ipow(dy, 2) + -0.000381319 *lens_ipow(y, 2)*dx*lens_ipow(dy, 2)*lens_ipow(lambda, 5) + 1.23342 *x*lens_ipow(dy, 8)*lambda + -1.98573e-14 *x*lens_ipow(y, 8)*lambda + -0.0658151 *dx*lens_ipow(lambda, 10) + -3.46228 *lens_ipow(dx, 3)*lens_ipow(dy, 2)*lens_ipow(lambda, 6) + -7.78967e-12 *lens_ipow(x, 7)*lens_ipow(lambda, 4) + -3.88049e-12 *lens_ipow(x, 8)*lens_ipow(dx, 3);
const float out_dy =  + 3.50026e-07  + -1.62701 *dy + -5.96379e-07 *dx + -0.0305295 *y + -0.000115299 *lens_ipow(dy, 2) + 7.72753e-05 *dx*dy + 0.957965 *lens_ipow(dy, 3) + 3.06826 *lens_ipow(dx, 2)*dy + -0.00177128 *y*lens_ipow(dy, 2) + 0.00624703 *y*lens_ipow(dx, 2) + -0.00060669 *lens_ipow(y, 2)*dy + -3.12343e-06 *lens_ipow(y, 3) + 0.0733683 *x*dx*dy + 0.000386863 *lens_ipow(x, 2)*dy + 1.01717e-06 *lens_ipow(x, 2)*y + 0.0286271 *dy*lens_ipow(lambda, 3) + -0.000601317 *y*lens_ipow(lambda, 3) + 7.60106e-07 *lens_ipow(x, 2)*lens_ipow(dy, 2) + -2.23455e-11 *x*lens_ipow(y, 4) + -5.63116e-07 *lens_ipow(x, 2)*y*lens_ipow(lambda, 2) + 1.1152e-12 *lens_ipow(y, 6) + -2.91732e-12 *lens_ipow(x, 3)*lens_ipow(y, 3) + 24.9269 *lens_ipow(dx, 2)*lens_ipow(dy, 5) + -4.27249e-09 *lens_ipow(y, 5)*lens_ipow(dx, 2) + -0.222089 *x*lens_ipow(dx, 5)*dy + -1.92606e-10 *lens_ipow(x, 6)*dy + -0.206353 *lens_ipow(dy, 3)*lens_ipow(lambda, 5) + -0.263576 *lens_ipow(dx, 2)*dy*lens_ipow(lambda, 5) + 0.00167185 *y*lens_ipow(lambda, 7) + -1.9303e-09 *lens_ipow(y, 5)*lens_ipow(lambda, 3) + 42.9703 *lens_ipow(dy, 9) + 136.043 *lens_ipow(dx, 4)*lens_ipow(dy, 5) + -3.63546e-13 *lens_ipow(y, 8)*dy + -3.19942e-05 *x*lens_ipow(y, 3)*dx*lens_ipow(dy, 4) + -8.28829e-13 *lens_ipow(x, 4)*lens_ipow(y, 4)*dy + -5.58107e-15 *lens_ipow(x, 8)*y + -0.070772 *dy*lens_ipow(lambda, 10) + 6.57936 *y*lens_ipow(dx, 10) + -9.62014e-17 *lens_ipow(x, 2)*lens_ipow(y, 9) + -3.60866e-12 *lens_ipow(x, 4)*lens_ipow(y, 3)*lens_ipow(lambda, 4);
const float out_transmittance =  + 0.695607  + 0.137175 *lambda + 5.30594e-06 *dx + 4.95315e-07 *y + -0.0143904 *lens_ipow(dy, 2) + -0.0113874 *lens_ipow(dx, 2) + -0.000567518 *y*dy + -1.74105e-05 *lens_ipow(y, 2) + -5.06374e-06 *x*dy + -0.000574729 *x*dx + -1.74568e-05 *lens_ipow(x, 2) + -0.115482 *lens_ipow(lambda, 3) + 1.14235e-05 *y*dx*dy + -0.000129153 *y*dy*lens_ipow(lambda, 2) + 0.000222905 *lens_ipow(y, 2)*lens_ipow(dy, 2) + 8.82067e-05 *lens_ipow(y, 2)*lens_ipow(dx, 2) + -0.000178599 *x*dx*lens_ipow(lambda, 2) + 0.000156553 *x*y*dx*dy + 8.9198e-05 *lens_ipow(x, 2)*lens_ipow(dy, 2) + 0.000204498 *lens_ipow(x, 2)*lens_ipow(dx, 2) + -1.11135e-10 *lens_ipow(x, 2)*lens_ipow(y, 3) + -7.68992 *lens_ipow(dx, 2)*lens_ipow(dy, 4) + -2.74706 *lens_ipow(dx, 6) + -4.20595e-10 *lens_ipow(y, 6) + -1.02128e-05 *lens_ipow(x, 2)*lens_ipow(dy, 2)*lens_ipow(lambda, 2) + -7.41878e-05 *lens_ipow(x, 2)*dx*lens_ipow(dy, 3) + -1.16018e-09 *lens_ipow(x, 2)*lens_ipow(y, 4) + -1.17593e-09 *lens_ipow(x, 4)*lens_ipow(y, 2) + -4.42264e-10 *lens_ipow(x, 6) + 0.00511415 *x*y*lens_ipow(dx, 3)*dy*lambda + -17.8435 *lens_ipow(dy, 8) + -58.0629 *lens_ipow(dx, 6)*lens_ipow(dy, 2) + 2.54104e-05 *x*lens_ipow(y, 3)*dx*lens_ipow(dy, 3) + 6.79813e-06 *lens_ipow(x, 4)*lens_ipow(dx, 4) + -5.78279e-11 *lens_ipow(x, 6)*y*dy + -0.98508 *lens_ipow(dx, 2)*lens_ipow(dy, 2)*lens_ipow(lambda, 5) + -0.186186 *lens_ipow(dx, 4)*lens_ipow(lambda, 5) + 1.5948e-08 *lens_ipow(y, 6)*lens_ipow(dy, 4) + -5.97846e-06 *lens_ipow(x, 3)*lens_ipow(y, 2)*lens_ipow(dx, 3)*lens_ipow(dy, 2) + 0.212409 *lens_ipow(lambda, 11);
//------------------------------------------------------------------------------
  outer = vec4(out_x, out_y, out_dx, out_dy);
  return out_transmittance;
}

void sample_ap(inout vec4 sensor, inout vec4 aperture)
{
  float x = sensor.x, y = sensor.y, dx = sensor.z, dy = sensor.w;
  float out_x = aperture.x, out_y = aperture.y, out_dx = aperture.z, out_dy = aperture.w;
//------------------------------------------------------------------------------
//---pt_sample_aperture.h-------------------------------------------------------
float pred_x;
float pred_y;
float pred_dx;
float pred_dy;
float sqr_err = FLT_MAX;
for(int k=0;k<5&&sqr_err > 1e-4f;k++)
{
  const float begin_x = x + dist * dx;
  const float begin_y = y + dist * dy;
  const float begin_dx = dx;
  const float begin_dy = dy;
  const float begin_lambda = lambda;
  pred_x =  + -2.39599e-05  + 0.000170703 *begin_dy + 50.3715 *begin_dx + 1.20467e-06 *begin_y + 0.792054 *begin_x + 0.00381455 *lens_ipow(begin_dx, 2) + -1.02586e-06 *lens_ipow(begin_x, 2) + 0.101015 *begin_dx*lens_ipow(begin_dy, 2) + 0.240904 *lens_ipow(begin_dx, 3) + 0.53457 *begin_y*begin_dx*begin_dy + 0.00916713 *lens_ipow(begin_y, 2)*begin_dx + 0.123822 *begin_x*lens_ipow(begin_dy, 2) + 0.658173 *begin_x*lens_ipow(begin_dx, 2) + 0.013701 *begin_x*begin_y*begin_dy + 0.000166393 *begin_x*lens_ipow(begin_y, 2) + -7.99231e-06 *lens_ipow(begin_x, 2)*begin_dy + 0.022954 *lens_ipow(begin_x, 2)*begin_dx + 0.000168299 *lens_ipow(begin_x, 3) + -0.0537531 *begin_dx*lens_ipow(begin_dy, 3) + 0.05381 *lens_ipow(begin_dx, 3)*begin_dy + 0.0553585 *begin_x*lens_ipow(begin_lambda, 3) + 3.57819 *begin_dx*lens_ipow(begin_lambda, 4) + 0.00194408 *lens_ipow(begin_y, 2)*begin_dx*lens_ipow(begin_dy, 2) + 6.06178e-06 *begin_x*lens_ipow(begin_y, 2)*lens_ipow(begin_lambda, 3) + 0.000318708 *lens_ipow(begin_x, 2)*lens_ipow(begin_dy, 4) + 0.00751021 *begin_x*begin_y*lens_ipow(begin_dy, 5) + 0.0267987 *lens_ipow(begin_x, 2)*begin_dx*lens_ipow(begin_dy, 4) + 4.90514e-05 *lens_ipow(begin_x, 3)*begin_y*lens_ipow(begin_dx, 2)*begin_dy + 1.80124e-09 *lens_ipow(begin_x, 6)*begin_dx + 0.0583189 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 6)*begin_dy + -0.144797 *lens_ipow(begin_x, 2)*lens_ipow(begin_dx, 5)*lens_ipow(begin_dy, 2) + 1.88889e-10 *lens_ipow(begin_x, 5)*lens_ipow(begin_y, 2)*lens_ipow(begin_lambda, 3) + 9.66981e-11 *lens_ipow(begin_x, 7)*lens_ipow(begin_lambda, 3) + -17.3519 *begin_dx*lens_ipow(begin_lambda, 10) + -2.25403 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 9) + -0.298715 *begin_x*lens_ipow(begin_lambda, 10) + 0.691116 *lens_ipow(begin_x, 2)*lens_ipow(begin_dx, 9) + 1.13012e-15 *lens_ipow(begin_x, 3)*lens_ipow(begin_y, 8) + 2.364e-08 *lens_ipow(begin_x, 7)*lens_ipow(begin_dy, 4) + 1.25188e-15 *lens_ipow(begin_x, 9)*lens_ipow(begin_y, 2);
  pred_y =  + 5.36909e-05  + 50.4606 *begin_dy + -7.98136e-05 *begin_dx + 0.793472 *begin_y + -7.02302e-07 *begin_x + 2.57149e-05 *begin_y*begin_dy + -6.7291e-06 *begin_x*begin_dy + -11.1019 *lens_ipow(begin_dy, 3) + -1.2863 *lens_ipow(begin_dx, 2)*begin_dy + 0.104314 *begin_y*lens_ipow(begin_dx, 2) + 0.0185838 *lens_ipow(begin_y, 2)*begin_dy + 0.00014928 *lens_ipow(begin_y, 3) + 0.504187 *begin_x*begin_dx*begin_dy + 0.013111 *begin_x*begin_y*begin_dx + 0.00900447 *lens_ipow(begin_x, 2)*begin_dy + 0.000161239 *lens_ipow(begin_x, 2)*begin_y + 0.0490546 *begin_y*lens_ipow(begin_lambda, 3) + 1.01948 *begin_y*lens_ipow(begin_dy, 2)*begin_lambda + 2.62835 *begin_dy*lens_ipow(begin_lambda, 4) + 35.2614 *lens_ipow(begin_dy, 3)*lens_ipow(begin_lambda, 2) + -0.00169844 *lens_ipow(begin_x, 2)*lens_ipow(begin_dy, 3) + 3.99946 *lens_ipow(begin_dx, 2)*begin_dy*lens_ipow(begin_lambda, 3) + 0.0127049 *lens_ipow(begin_y, 2)*begin_dy*lens_ipow(begin_lambda, 3) + 0.043055 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 2)*lens_ipow(begin_dy, 3) + 0.00229194 *begin_x*begin_y*lens_ipow(begin_dx, 5) + 4.37128e-05 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 2)*begin_dy + 0.0655554 *begin_y*lens_ipow(begin_dx, 4)*lens_ipow(begin_lambda, 4) + -0.0030881 *lens_ipow(begin_y, 3)*lens_ipow(begin_dy, 6) + -0.00228639 *lens_ipow(begin_x, 2)*begin_dy*lens_ipow(begin_lambda, 6) + -17.2517 *lens_ipow(begin_dy, 5)*lens_ipow(begin_lambda, 5) + 0.00147989 *lens_ipow(begin_y, 3)*lens_ipow(begin_dx, 2)*lens_ipow(begin_lambda, 5) + -3.60966e-14 *lens_ipow(begin_y, 9)*begin_lambda + -9.44334e-14 *begin_x*lens_ipow(begin_y, 8)*begin_dx + -12.1588 *begin_dy*lens_ipow(begin_lambda, 10) + -77.0589 *lens_ipow(begin_dy, 3)*lens_ipow(begin_lambda, 8) + -0.24787 *begin_y*lens_ipow(begin_lambda, 10) + 2.87156e-07 *lens_ipow(begin_y, 5)*lens_ipow(begin_lambda, 6) + 0.000274665 *begin_x*lens_ipow(begin_y, 3)*begin_dx*lens_ipow(begin_dy, 2)*lens_ipow(begin_lambda, 4) + 1.22464e-12 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 7)*lens_ipow(begin_lambda, 2) + 4.54446e-15 *lens_ipow(begin_x, 6)*lens_ipow(begin_y, 5);
  pred_dx =  + -1.85904e-07  + 0.608182 *begin_dx + -3.83357e-08 *begin_y + -0.0102713 *begin_x + 7.47142e-05 *lens_ipow(begin_dx, 2) + 7.60151e-07 *begin_y*begin_dy + 3.78042e-08 *begin_x*begin_dy + -0.534525 *begin_dx*lens_ipow(begin_dy, 2) + -0.513478 *lens_ipow(begin_dx, 3) + -2.51529e-05 *begin_y*lens_ipow(begin_dx, 2) + 0.000139479 *lens_ipow(begin_y, 2)*begin_dx + -0.00216452 *begin_x*lens_ipow(begin_dy, 2) + 0.000337277 *begin_x*begin_y*begin_dy + 3.87528e-06 *begin_x*lens_ipow(begin_y, 2) + 0.000416054 *lens_ipow(begin_x, 2)*begin_dx + 1.17825e-08 *lens_ipow(begin_x, 2)*begin_y + 0.00225279 *begin_x*lens_ipow(begin_lambda, 3) + 6.0162e-06 *lens_ipow(begin_x, 3)*begin_lambda + -0.0112627 *begin_x*lens_ipow(begin_dx, 2)*lens_ipow(begin_lambda, 2) + 9.42784e-10 *begin_x*lens_ipow(begin_y, 4) + 1.44429e-05 *lens_ipow(begin_x, 3)*lens_ipow(begin_dy, 2) + 4.22513e-09 *lens_ipow(begin_x, 3)*lens_ipow(begin_y, 2) + 3.14997e-09 *lens_ipow(begin_x, 5) + 0.242838 *begin_dx*lens_ipow(begin_lambda, 5) + 1.89559e-06 *begin_x*lens_ipow(begin_y, 2)*lens_ipow(begin_lambda, 3) + -4.01038e-05 *lens_ipow(begin_x, 2)*begin_y*begin_dx*begin_dy*begin_lambda + 0.000885232 *begin_x*begin_y*lens_ipow(begin_dy, 5) + -0.000136782 *lens_ipow(begin_x, 3)*lens_ipow(begin_dx, 2)*lens_ipow(begin_dy, 2) + 0.00801079 *begin_x*begin_y*lens_ipow(begin_dx, 2)*lens_ipow(begin_dy, 5) + 0.000654954 *lens_ipow(begin_x, 2)*begin_y*lens_ipow(begin_dx, 5)*begin_dy + -0.000435043 *lens_ipow(begin_x, 3)*lens_ipow(begin_dx, 6) + -9.0387e-05 *lens_ipow(begin_x, 3)*lens_ipow(begin_dx, 2)*lens_ipow(begin_lambda, 5) + -0.901541 *begin_dx*lens_ipow(begin_lambda, 10) + -1.65351 *lens_ipow(begin_dx, 3)*lens_ipow(begin_lambda, 8) + -19.0024 *lens_ipow(begin_dx, 3)*lens_ipow(begin_dy, 2)*lens_ipow(begin_lambda, 6) + -49.199 *lens_ipow(begin_dx, 7)*lens_ipow(begin_lambda, 4) + 0.00168554 *lens_ipow(begin_y, 2)*begin_dx*lens_ipow(begin_dy, 2)*lens_ipow(begin_lambda, 6) + -0.011703 *begin_x*lens_ipow(begin_lambda, 10) + -6.49904e-05 *lens_ipow(begin_x, 3)*lens_ipow(begin_dy, 2)*lens_ipow(begin_lambda, 6) + -5.26622e-07 *lens_ipow(begin_x, 5)*lens_ipow(begin_dy, 6);
  pred_dy =  + 2.84649e-06  + 0.607813 *begin_dy + -1.87293e-05 *begin_dx + -0.0103448 *begin_y + -4.74827e-07 *begin_x + 1.78656e-06 *begin_y*begin_dy + 3.22449e-06 *begin_y*begin_dx + -0.524951 *lens_ipow(begin_dy, 3) + -0.48381 *lens_ipow(begin_dx, 2)*begin_dy + 0.000545522 *lens_ipow(begin_y, 2)*begin_dy + 4.27867e-06 *lens_ipow(begin_y, 3) + 0.000431408 *begin_x*begin_y*begin_dx + 4.40997e-06 *lens_ipow(begin_x, 2)*begin_y + 0.00246819 *begin_y*lens_ipow(begin_lambda, 3) + 1.34405e-06 *lens_ipow(begin_y, 3)*begin_lambda + -8.36484e-05 *begin_x*lens_ipow(begin_dx, 2)*begin_dy + 0.00023829 *lens_ipow(begin_x, 2)*begin_dy*begin_lambda + 6.31703e-07 *lens_ipow(begin_y, 3)*lens_ipow(begin_dx, 2) + 4.57173e-10 *lens_ipow(begin_y, 5) + -0.00016404 *begin_x*begin_y*begin_dx*lens_ipow(begin_lambda, 2) + 3.20539e-11 *begin_x*lens_ipow(begin_y, 4) + 9.79731e-05 *lens_ipow(begin_x, 2)*lens_ipow(begin_dy, 3) + 1.33789e-09 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 3) + 1.23125e-07 *lens_ipow(begin_x, 4)*begin_dy + 0.243968 *begin_dy*lens_ipow(begin_lambda, 5) + -2.52174 *lens_ipow(begin_dx, 4)*begin_dy*lens_ipow(begin_lambda, 2) + 1.02018e-08 *lens_ipow(begin_x, 4)*begin_y*lens_ipow(begin_lambda, 2) + 0.00239545 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 2)*begin_dy*lens_ipow(begin_lambda, 4) + -9.8144e-05 *lens_ipow(begin_y, 3)*lens_ipow(begin_dy, 6) + 0.0207298 *begin_x*begin_y*lens_ipow(begin_dx, 5)*lens_ipow(begin_dy, 2) + 0.00782519 *begin_x*begin_y*lens_ipow(begin_dx, 7) + -0.000942376 *begin_x*lens_ipow(begin_y, 2)*begin_dx*lens_ipow(begin_dy, 5) + 3.16607e-07 *lens_ipow(begin_y, 4)*begin_dy*lens_ipow(begin_lambda, 5) + -0.955327 *begin_dy*lens_ipow(begin_lambda, 10) + -69.66 *lens_ipow(begin_dx, 2)*lens_ipow(begin_dy, 5)*lens_ipow(begin_lambda, 4) + -0.0128775 *begin_y*lens_ipow(begin_lambda, 10) + -1.4892e-09 *lens_ipow(begin_y, 5)*begin_dx*lens_ipow(begin_lambda, 5) + 0.00783274 *begin_x*begin_y*lens_ipow(begin_dx, 3)*lens_ipow(begin_lambda, 6) + -0.000645324 *lens_ipow(begin_x, 2)*begin_dy*lens_ipow(begin_lambda, 8) + 7.24739e-17 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 9);
  float dx1_domega0[2][2];
  dx1_domega0[0][0] =  + 50.3715  + 0.0076291 *begin_dx + 0.101015 *lens_ipow(begin_dy, 2) + 0.722713 *lens_ipow(begin_dx, 2) + 0.53457 *begin_y*begin_dy + 0.00916713 *lens_ipow(begin_y, 2) + 1.31635 *begin_x*begin_dx + 0.022954 *lens_ipow(begin_x, 2) + -0.0537531 *lens_ipow(begin_dy, 3) + 0.16143 *lens_ipow(begin_dx, 2)*begin_dy + 3.57819 *lens_ipow(begin_lambda, 4) + 0.00194408 *lens_ipow(begin_y, 2)*lens_ipow(begin_dy, 2) + 0.0267987 *lens_ipow(begin_x, 2)*lens_ipow(begin_dy, 4) + 9.81029e-05 *lens_ipow(begin_x, 3)*begin_y*begin_dx*begin_dy + 1.80124e-09 *lens_ipow(begin_x, 6) + 0.349913 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 5)*begin_dy + -0.723987 *lens_ipow(begin_x, 2)*lens_ipow(begin_dx, 4)*lens_ipow(begin_dy, 2) + -17.3519 *lens_ipow(begin_lambda, 10) + -20.2862 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 8) + 6.22004 *lens_ipow(begin_x, 2)*lens_ipow(begin_dx, 8)+0.0f;
  dx1_domega0[0][1] =  + 0.000170703  + 0.202031 *begin_dx*begin_dy + 0.53457 *begin_y*begin_dx + 0.247643 *begin_x*begin_dy + 0.013701 *begin_x*begin_y + -7.99231e-06 *lens_ipow(begin_x, 2) + -0.161259 *begin_dx*lens_ipow(begin_dy, 2) + 0.05381 *lens_ipow(begin_dx, 3) + 0.00388817 *lens_ipow(begin_y, 2)*begin_dx*begin_dy + 0.00127483 *lens_ipow(begin_x, 2)*lens_ipow(begin_dy, 3) + 0.0375511 *begin_x*begin_y*lens_ipow(begin_dy, 4) + 0.107195 *lens_ipow(begin_x, 2)*begin_dx*lens_ipow(begin_dy, 3) + 4.90514e-05 *lens_ipow(begin_x, 3)*begin_y*lens_ipow(begin_dx, 2) + 0.0583189 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 6) + -0.289595 *lens_ipow(begin_x, 2)*lens_ipow(begin_dx, 5)*begin_dy + 9.456e-08 *lens_ipow(begin_x, 7)*lens_ipow(begin_dy, 3)+0.0f;
  dx1_domega0[1][0] =  + -7.98136e-05  + -2.5726 *begin_dx*begin_dy + 0.208628 *begin_y*begin_dx + 0.504187 *begin_x*begin_dy + 0.013111 *begin_x*begin_y + 7.99892 *begin_dx*begin_dy*lens_ipow(begin_lambda, 3) + 0.08611 *lens_ipow(begin_y, 2)*begin_dx*lens_ipow(begin_dy, 3) + 0.0114597 *begin_x*begin_y*lens_ipow(begin_dx, 4) + 8.74257e-05 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 2)*begin_dx*begin_dy + 0.262222 *begin_y*lens_ipow(begin_dx, 3)*lens_ipow(begin_lambda, 4) + 0.00295979 *lens_ipow(begin_y, 3)*begin_dx*lens_ipow(begin_lambda, 5) + -9.44334e-14 *begin_x*lens_ipow(begin_y, 8) + 0.000274665 *begin_x*lens_ipow(begin_y, 3)*lens_ipow(begin_dy, 2)*lens_ipow(begin_lambda, 4)+0.0f;
  dx1_domega0[1][1] =  + 50.4606  + 2.57149e-05 *begin_y + -6.7291e-06 *begin_x + -33.3056 *lens_ipow(begin_dy, 2) + -1.2863 *lens_ipow(begin_dx, 2) + 0.0185838 *lens_ipow(begin_y, 2) + 0.504187 *begin_x*begin_dx + 0.00900447 *lens_ipow(begin_x, 2) + 2.03896 *begin_y*begin_dy*begin_lambda + 2.62835 *lens_ipow(begin_lambda, 4) + 105.784 *lens_ipow(begin_dy, 2)*lens_ipow(begin_lambda, 2) + -0.00509533 *lens_ipow(begin_x, 2)*lens_ipow(begin_dy, 2) + 3.99946 *lens_ipow(begin_dx, 2)*lens_ipow(begin_lambda, 3) + 0.0127049 *lens_ipow(begin_y, 2)*lens_ipow(begin_lambda, 3) + 0.129165 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 2)*lens_ipow(begin_dy, 2) + 4.37128e-05 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 2) + -0.0185286 *lens_ipow(begin_y, 3)*lens_ipow(begin_dy, 5) + -0.00228639 *lens_ipow(begin_x, 2)*lens_ipow(begin_lambda, 6) + -86.2583 *lens_ipow(begin_dy, 4)*lens_ipow(begin_lambda, 5) + -12.1588 *lens_ipow(begin_lambda, 10) + -231.177 *lens_ipow(begin_dy, 2)*lens_ipow(begin_lambda, 8) + 0.000549331 *begin_x*lens_ipow(begin_y, 3)*begin_dx*begin_dy*lens_ipow(begin_lambda, 4)+0.0f;
  float invJ[2][2];
  const float invdet = 1.0f/(dx1_domega0[0][0]*dx1_domega0[1][1] - dx1_domega0[0][1]*dx1_domega0[1][0]);
  invJ[0][0] =  dx1_domega0[1][1]*invdet;
  invJ[1][1] =  dx1_domega0[0][0]*invdet;
  invJ[0][1] = -dx1_domega0[0][1]*invdet;
  invJ[1][0] = -dx1_domega0[1][0]*invdet;
  const float dx1[2] = {out_x - pred_x, out_y - pred_y};
  for(int i=0;i<2;i++)
  {
    dx += invJ[0][i]*dx1[i];
    dy += invJ[1][i]*dx1[i];
  }
  sqr_err = dx1[0]*dx1[0] + dx1[1]*dx1[1];
}
out_dx = pred_dx;
out_dy = pred_dy;

//------------------------------------------------------------------------------
  sensor = vec4(x, y, dx, dy);
  aperture = vec4(out_x, out_y, out_dx, out_dy);
}

vec4 traceRay(vec3 position, vec3 direction, float transmittance)
{
  vec4 ret = vec4(0,0,0,1);
  vec3 pos = position;
  vec3 dir = direction;

  float near = 2*lens_outer_pupil_curvature_radius;
  float far = 20000;
  float t[12];
  t[0] = (-pos.x-near)/dir.x;
  t[1] = (-pos.x+near)/dir.x;
  t[2] = (-pos.y-near)/dir.y;
  t[3] = (-pos.y+near)/dir.y;
  t[4] = (-pos.z-near)/dir.z;
  t[5] = (-pos.z+near)/dir.z;

  t[6] = (-pos.x-far)/dir.x;
  t[7] = (-pos.x+far)/dir.x;
  t[8] = (-pos.y-far)/dir.y;
  t[9] = (-pos.y+far)/dir.y;
  t[10] = (-pos.z-far)/dir.z;
  t[11] = (-pos.z+far)/dir.z;

  int mint = 0;
  for(int i = 1; i < 6; i++)
    if((t[mint] < 0 || t[mint] > t[i]) && t[i] > 0)
      mint = i;

  int maxt = mint;
  for(int i = 0; i < 6; i++)
    if((t[maxt+6] < 0 || t[maxt+6] > t[i+6]) && t[i+6] > 0)
      maxt = i;

  int faceIdx = mint>>1;
  int faceIdx2 = maxt>>1;
  int sig = sign(mint&1)*2-1;
  int sig2 = sign(maxt&1)*2-1;

  vec3 r0 = (pos + t[mint] * dir)/(near*2)+0.5;
  r0[faceIdx] = 0;
  vec3 rmax = (pos + t[mint+6] * dir)/(far*2)+0.5;
  rmax[faceIdx] = sig;
  vec3 rd = rmax - r0;
  rd = normalize(rd);

  vec3 lookupOff = vec3(-1);
  lookupOff[faceIdx] = sig;

  vec3 lookupFac = vec3(2);
  lookupFac[faceIdx] = 0;

  vec3 r02 = (pos + t[maxt] * dir)/(near*2)+0.5;
  r02[faceIdx2] = 0;
  vec3 rmax2 = (pos + t[maxt+6] * dir)/(far*2)+0.5;
  rmax2[faceIdx2] = sig2;
  vec3 rd2 = rmax2 - r02;
  rd2 = normalize(rd2);

  vec3 lookupOff2 = vec3(-1);
  lookupOff2[faceIdx2] = sig2;

  vec3 lookupFac2 = vec3(2);
  lookupFac2[faceIdx2] = 0;

  const int maxLod = 9;
  int lod = maxLod;
  vec4 color = vec4(1);
  // factor for size of one texel (1 = whole image in 1 texel, 
  // 1/2 = 2 texels for whole image, ...) texelSize = 1/(2^(10-lod))
  int numIterations = 0;

  for(int i = 0; i < 20; i++,numIterations++)
  {
    if(r0[(faceIdx+1)%3] > 1 || r0[(faceIdx+2)%3] > 1 || r0[(faceIdx+1)%3] < 0 || r0[(faceIdx+2)%3] < 0)
    {
      if(faceIdx == faceIdx2)
        break;
      float prevDepth = r0[faceIdx];
      faceIdx = faceIdx2;
      sig = sig2;
      lookupOff = lookupOff2;
      lookupFac = lookupFac2;
      rd = rd2;
      r0 = r02;
      float t = (prevDepth - abs(r0[faceIdx])) / abs(rd[faceIdx]);
      r0 += t * rd;

      lod = maxLod;
    }

    float texelSize = 1.0f/(1<<(9-lod));

    vec2 minmaxDepth = (textureLod(minmaxdepthmap, r0 * lookupFac + lookupOff, lod).rg)/(far);
    //TODO dependency on dimensions of ray bundle
    color.rgb = textureLod(cubemap, r0 * lookupFac + lookupOff, 0).rgb;
    color.rgb = textureLod(cubemap, r0 * lookupFac + lookupOff, 0).rgb;
    float dist = -1;

    // if the current position is before the min-plane, choose max step size s.t. we reach the min-plane,
    // if current ray position is between min and max depth, look at higher resolution depth (i.e. lod = lod-1)
    // otherwise (current depth greater than the maximum) go to next texel but choose lower resolution for next iteration
    // in any case the maximum step size is also limited by the texel size.
    if(abs(r0[faceIdx]) < minmaxDepth.r)
      dist = (minmaxDepth.r - abs(r0[faceIdx])) / abs(rd[faceIdx]);
    else if(abs(r0[faceIdx]) < minmaxDepth.g)
    {
      if(minmaxDepth.g - minmaxDepth.r < 1e-2)
        break;
      lod = max(lod-1, 0);numIterations--;
      continue;
    }
    else
    {
      lod = min(lod+1, maxLod);numIterations--;
      continue;
    }

    vec2 inTexelPos = mod(vec2(r0[(faceIdx+1)%3], r0[(faceIdx+2)%3]), texelSize);
    vec2 inTexelDir = vec2(rd[(faceIdx+1)%3], rd[(faceIdx+2)%3]);

    vec2 texelBorder = vec2(sign(inTexelDir.x)*texelSize, sign(inTexelDir.y)*texelSize);
    texelBorder = clamp(texelBorder, 0, texelSize);
    vec2 texelIntersect = (texelBorder-inTexelPos) / (inTexelDir);
    dist = min(texelIntersect.x, min(dist, texelIntersect.y));

    r0 += dist*(1+1e-7) * rd;
  }
  color.rgb *= transmittance;
  ret += color;
  return ret;
}

vec2 lens_sample_aperture(vec2 r, const float radius, const int blades)
{
  const int tri = int(r.x*blades);
  // rescale:
  r.x = r.x*blades - tri;

  // sample triangle:
  vec2 bary = vec2(1.0f-r.y, r.y)*sqrt(r.x);

  vec2 p1, p2;
  p1 = vec2(sin(2.0f*M_PI/blades * (tri+1)), cos(2.0f*M_PI/blades * (tri+1)));
  p2 = vec2(sin(2.0f*M_PI/blades * tri), cos(2.0f*M_PI/blades * tri));

  return radius * (bary.x * p1 + bary.y * p2);
}

void main()
{    
  vec4 center = vec4(sensorPos, -sensorPos/(lens_length-lens_aperture_pos+dist));
  vec3 p, d;
  float t;
  vec4 color = vec4(0.0);

  for(int i = 0; i < 144; i++)
  {
    vec4 ray = center;
    //sample aperture (as disk)
    vec4 aperture = vec4(0);
    vec2 s = fract(vec2(1,89)*i/float(144));
    aperture.xy = lens_sample_aperture(s, lens_aperture_housing_radius*apfac, 5);
    sample_ap(ray, aperture);
    vec4 outer;
    float t = eval(ray, outer);
    lens_sphereToCs(outer.xy, outer.zw, p, d, 0, lens_outer_pupil_curvature_radius);
    if(length(outer.xy) > lens_outer_pupil_radius)
      t = 0;
    color += traceRay(p, d, t);
  }
  col = color/color.a/exposure;
}
