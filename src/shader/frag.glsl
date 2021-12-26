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
const float lens_outer_pupil_radius = 13.000000; // scene facing radius in mm
const float lens_inner_pupil_radius = 13.000000; // sensor facing radius in mm
const float lens_length = 115.919998; // overall lens length in mm
const float lens_focal_length = 85.000000; // approximate lens focal length in mm (BFL)
const float lens_aperture_pos = 14.630000; // distance aperture -> outer pupil in mm
const float lens_aperture_housing_radius = 10.000000; // lens housing radius at the aperture
const float lens_outer_pupil_curvature_radius = 22.660000; // radius of curvature of the outer pupil
const float lens_field_of_view = 0.976992; // cosine of the approximate field of view assuming a 35mm image

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
const float out_x =  + -3.22831e-05  + 98.9954 *dx + 8.64056e-06 *y + 0.851601 *x + 7.06489e-05 *y*dy + -0.00045637 *x*dx + -9.12665e-07 *x*y + -11.9225 *dx*lens_ipow(dy, 2) + -0.0620116 *lens_ipow(dx, 2)*dy + -12.5939 *lens_ipow(dx, 3) + 0.855524 *y*dx*dy + 0.00978113 *lens_ipow(y, 2)*dx + 2.72831 *x*lens_ipow(dy, 2) + 3.52654 *x*lens_ipow(dx, 2) + 0.06051 *x*y*dy + 0.000333285 *x*lens_ipow(y, 2) + 0.0697881 *lens_ipow(x, 2)*dx + -1.83976e-07 *lens_ipow(x, 2)*y + 0.000332212 *lens_ipow(x, 3) + 0.560816 *dx*lens_ipow(lambda, 3) + 9.48281e-05 *lens_ipow(y, 2)*dx*dy + 9.80161e-07 *lens_ipow(x, 2)*y*dx + 1.99546e-08 *lens_ipow(x, 2)*lens_ipow(y, 2) + -2.63115e-08 *lens_ipow(x, 4) + -0.96998 *x*lens_ipow(dy, 4) + 0.000159734 *x*lens_ipow(y, 2)*lens_ipow(dx, 2) + 0.000115625 *lens_ipow(x, 3)*lens_ipow(dy, 2) + 0.177637 *y*lens_ipow(dx, 4)*dy + 3052.74 *lens_ipow(dx, 5)*lens_ipow(dy, 2) + 7.24368e-07 *x*lens_ipow(y, 4)*lens_ipow(dy, 2) + -2.45584e-05 *lens_ipow(x, 4)*lens_ipow(dx, 3) + 7761.65 *lens_ipow(dx, 9) + 0.00619141 *x*lens_ipow(lambda, 8) + -2.09816e-13 *lens_ipow(x, 3)*lens_ipow(y, 6) + -2.07048 *dx*lens_ipow(lambda, 10) + 229717 *lens_ipow(dx, 3)*lens_ipow(dy, 8) + 1947.01 *y*lens_ipow(dx, 9)*dy + -1.78309e-12 *lens_ipow(y, 9)*dx*dy + -3.75539e-06 *lens_ipow(x, 4)*lens_ipow(y, 2)*lens_ipow(dx, 3)*lens_ipow(dy, 2) + -4.48372e-16 *lens_ipow(x, 9)*lens_ipow(y, 2);
const float out_y =  + 0.000215368  + 99.0277 *dy + 0.85144 *y + 0.00779489 *lens_ipow(dy, 2) + -1.90803e-06 *lens_ipow(y, 2) + -3.60465e-05 *x*dy + 3.71504e-06 *x*y + -1.08268e-06 *lens_ipow(x, 2) + -18.2158 *lens_ipow(dy, 3) + -14.6602 *lens_ipow(dx, 2)*dy + 3.51929 *y*lens_ipow(dy, 2) + 2.72982 *y*lens_ipow(dx, 2) + 0.0699987 *lens_ipow(y, 2)*dy + 0.000333978 *lens_ipow(y, 3) + 0.804093 *x*dx*dy + 4.70624e-06 *x*y*dy + 0.0604572 *x*y*dx + 0.00954859 *lens_ipow(x, 2)*dy + 0.000334072 *lens_ipow(x, 2)*y + 0.601682 *dy*lens_ipow(lambda, 3) + -0.000166479 *x*y*lens_ipow(dy, 2) + 108.828 *lens_ipow(dy, 5) + 199.59 *lens_ipow(dx, 2)*lens_ipow(dy, 3) + -0.0296537 *x*y*dx*lens_ipow(dy, 2) + 6.65726e-05 *lens_ipow(x, 3)*dx*dy + 9.16143e-11 *x*lens_ipow(y, 5) + -8.4933e-11 *lens_ipow(x, 5)*y + -10.4301 *y*lens_ipow(dx, 6) + -3.29962e-05 *lens_ipow(y, 4)*lens_ipow(dy, 3) + 1.62515e-09 *lens_ipow(x, 6)*dy + 0.00651726 *y*lens_ipow(lambda, 7) + -781.74 *lens_ipow(dy, 9) + 15863.5 *lens_ipow(dx, 4)*lens_ipow(dy, 5) + 5892.54 *lens_ipow(dx, 8)*dy + -2.49673e-13 *lens_ipow(x, 4)*lens_ipow(y, 5) + -1.78325e-07 *lens_ipow(x, 5)*y*lens_ipow(dx, 3)*lambda + -2.20614 *dy*lens_ipow(lambda, 10) + 3.89814e-08 *lens_ipow(x, 3)*lens_ipow(y, 4)*lens_ipow(dx, 3)*dy + -0.00279027 *lens_ipow(x, 4)*lens_ipow(dy, 7) + -5.61046e-08 *lens_ipow(x, 4)*y*lens_ipow(lambda, 6);
const float out_dx =  + -3.87931e-05  + 8.04706e-05 *dy + -4.37477 *dx + -0.0477281 *x + 0.00137204 *lens_ipow(dy, 2) + 0.000114396 *lens_ipow(dx, 2) + -5.13362e-08 *lens_ipow(y, 2) + 6.53217e-06 *x*dy + 0.000210975 *lens_ipow(lambda, 3) + -0.0103629 *dx*lens_ipow(lambda, 2) + -44.9562 *dx*lens_ipow(dy, 2) + 2.23176 *lens_ipow(dx, 3) + -0.844475 *y*dx*dy + 5.12007e-05 *y*lens_ipow(dx, 2) + -0.00378975 *lens_ipow(y, 2)*dx + -0.519422 *x*lens_ipow(dy, 2) + -0.00972587 *x*y*dy + -4.36122e-05 *x*lens_ipow(y, 2) + 5.22284e-07 *lens_ipow(x, 2)*dy + -0.000457882 *lens_ipow(x, 2)*dx + -2.08698e-06 *lens_ipow(x, 3) + 8.96613e-05 *x*lens_ipow(lambda, 3) + -9.74594e-07 *lens_ipow(x, 2)*lens_ipow(lambda, 2) + 1.40481e-09 *lens_ipow(x, 4) + -0.0453125 *lens_ipow(dy, 5) + -0.666163 *lens_ipow(dx, 5) + 1.94178e-09 *lens_ipow(x, 3)*lens_ipow(y, 2) + 0.0236709 *y*lens_ipow(dx, 2)*lens_ipow(dy, 3) + 2.50983 *x*lens_ipow(dx, 2)*lens_ipow(dy, 4) + 0.000149893 *x*lens_ipow(y, 2)*lens_ipow(dy, 4) + -6.77348e-08 *lens_ipow(x, 3)*lens_ipow(y, 2)*lens_ipow(dy, 2) + -5.90098e-08 *lens_ipow(x, 3)*lens_ipow(y, 2)*lens_ipow(dx, 2) + -0.0778133 *x*lens_ipow(dy, 7) + -9.89879 *y*dx*lens_ipow(dy, 7) + 127.613 *lens_ipow(dx, 3)*lens_ipow(dy, 4)*lens_ipow(lambda, 3) + 27.478 *y*lens_ipow(dx, 7)*dy*lambda + -6.98928e-06 *x*lens_ipow(y, 2)*lens_ipow(dx, 2)*lens_ipow(lambda, 5) + 0.0801192 *dx*lens_ipow(lambda, 10) + 96671 *lens_ipow(dx, 7)*lens_ipow(dy, 4) + 4.4274e-05 *lens_ipow(x, 3)*lens_ipow(y, 2)*lens_ipow(dx, 4)*lens_ipow(dy, 2);
const float out_dy =  + -6.5922e-06  + -4.39309 *dy + -7.30806e-05 *dx + -0.0479157 *y + -8.51436e-07 *x + 0.00113672 *lens_ipow(dy, 2) + -0.00235471 *dx*dy + 0.000713114 *lens_ipow(dx, 2) + -1.74059e-05 *x*dy + 3.77937 *lens_ipow(dy, 3) + 0.0115852 *dx*lens_ipow(dy, 2) + 49.7177 *lens_ipow(dx, 2)*dy + 0.0469349 *y*lens_ipow(dy, 2) + 0.325336 *y*lens_ipow(dx, 2) + 1.22264e-05 *lens_ipow(y, 2)*dy + -5.10009e-07 *lens_ipow(y, 3) + 1.0517 *x*dx*dy + 0.00718422 *x*y*dx + 5.18215e-09 *x*lens_ipow(y, 2) + 0.00558656 *lens_ipow(x, 2)*dy + 4.00401e-05 *lens_ipow(x, 2)*y + 0.000212037 *y*lens_ipow(lambda, 3) + -3.13589e-05 *y*dx*lens_ipow(lambda, 2) + -0.000511296 *x*lens_ipow(dy, 3) + -1.55373 *lens_ipow(dx, 4)*dy + 0.0255669 *y*lens_ipow(dx, 2)*lens_ipow(dy, 2) + -0.00945507 *lens_ipow(dx, 2)*lens_ipow(lambda, 4) + 1.06264e-08 *lens_ipow(x, 2)*lens_ipow(y, 2)*lens_ipow(dx, 2) + 0.000628738 *x*lens_ipow(dy, 2)*lens_ipow(lambda, 4) + 3.00163e-06 *lens_ipow(x, 4)*lens_ipow(dx, 2)*dy + -0.457613 *x*lens_ipow(dx, 4)*lens_ipow(dy, 3) + -1.26594e-06 *lens_ipow(x, 4)*lens_ipow(dy, 4) + -3.52468e-10 *lens_ipow(x, 6)*dy*lambda + -1.04874e-09 *lens_ipow(x, 5)*y*lens_ipow(dy, 2)*lens_ipow(lambda, 2) + -1194.25 *lens_ipow(dy, 11) + -10493.6 *lens_ipow(dx, 10)*dy + -0.0010462 *y*lens_ipow(lambda, 10) + -2.39328e-05 *x*lens_ipow(y, 2)*dx*dy*lens_ipow(lambda, 6) + -2.64222e-06 *lens_ipow(x, 2)*lens_ipow(y, 3)*lens_ipow(dx, 6) + 5.61379e-07 *lens_ipow(x, 4)*lens_ipow(dy, 2)*lens_ipow(lambda, 5);
const float out_transmittance =  + 0.621638  + 0.151228 *lambda + -0.000173018 *dy + -2.08723e-06 *y + -8.78735e-06 *x + -0.811103 *lens_ipow(dy, 2) + 0.000103358 *dx*lambda + -0.00118958 *dx*dy + -0.791182 *lens_ipow(dx, 2) + -0.0175219 *y*dy + -9.46734e-05 *lens_ipow(y, 2) + -0.0171096 *x*dx + -9.65303e-05 *lens_ipow(x, 2) + -0.126351 *lens_ipow(lambda, 3) + -0.0324511 *lens_ipow(dx, 3) + 0.000193553 *x*lens_ipow(dy, 2) + -5.748e-06 *x*y*dx + -4.47266e-08 *x*lens_ipow(y, 2) + 1.37065e-05 *lens_ipow(x, 2)*dx + 1.42992e-07 *lens_ipow(x, 3) + -1.18148 *lens_ipow(dy, 4) + -3.83757 *lens_ipow(dx, 2)*lens_ipow(dy, 2) + -0.838289 *lens_ipow(dx, 4) + 6.63597e-05 *lens_ipow(y, 2)*lens_ipow(dx, 2) + -6.02733e-06 *x*lens_ipow(y, 2)*dx + 0.000361467 *lens_ipow(x, 2)*lens_ipow(dy, 2) + -6.26128e-08 *lens_ipow(x, 2)*lens_ipow(y, 2) + 1.30085e-09 *lens_ipow(x, 3)*y + -0.00454509 *y*lens_ipow(dx, 4) + 1.39042e-08 *lens_ipow(x, 2)*lens_ipow(y, 2)*dy + -1.65048e-08 *lens_ipow(y, 5)*dy + -1.27553e-10 *lens_ipow(y, 6) + -0.000664688 *lens_ipow(x, 2)*lens_ipow(dx, 2)*lens_ipow(lambda, 2) + -2.29946e-08 *lens_ipow(x, 5)*dx + 3.11003e-05 *lens_ipow(x, 2)*lens_ipow(lambda, 5) + -4.5113e-13 *lens_ipow(x, 8) + -769.049 *lens_ipow(dy, 10) + -1423.88 *lens_ipow(dx, 10) + 0.212642 *lens_ipow(lambda, 11) + 73.4435 *lens_ipow(dx, 6)*lens_ipow(lambda, 5);
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
  pred_x =  + -2.0682e-05  + 81.4095 *begin_dx + 4.22792e-07 *begin_y + 0.814319 *begin_x + 0.000352617 *lens_ipow(begin_dy, 2) + 0.0026206 *lens_ipow(begin_dx, 2) + 3.14916e-05 *begin_y*begin_dx + 2.54121e-07 *begin_x*begin_y + -68.2088 *begin_dx*lens_ipow(begin_dy, 2) + -68.6124 *lens_ipow(begin_dx, 3) + -0.887353 *begin_y*begin_dx*begin_dy + -0.00229716 *lens_ipow(begin_y, 2)*begin_dx + -0.486128 *begin_x*lens_ipow(begin_dy, 2) + -1.37078 *begin_x*lens_ipow(begin_dx, 2) + -0.00533203 *begin_x*begin_y*begin_dy + -8.17446e-06 *begin_x*lens_ipow(begin_y, 2) + -9.42069e-07 *lens_ipow(begin_x, 2)*begin_dy + -0.00752169 *lens_ipow(begin_x, 2)*begin_dx + -7.91928e-06 *lens_ipow(begin_x, 3) + 2.02778 *begin_dx*lens_ipow(begin_lambda, 3) + 20.0561 *lens_ipow(begin_dx, 5) + 0.0282357 *begin_x*lens_ipow(begin_lambda, 4) + -0.00421329 *lens_ipow(begin_x, 2)*begin_dx*lens_ipow(begin_dy, 2) + -0.00385239 *lens_ipow(begin_x, 2)*lens_ipow(begin_dx, 3) + 60.4562 *lens_ipow(begin_dx, 3)*lens_ipow(begin_dy, 2)*begin_lambda + -3.2533 *lens_ipow(begin_dx, 4)*lens_ipow(begin_dy, 2) + 0.0799746 *lens_ipow(begin_y, 2)*begin_dx*lens_ipow(begin_dy, 4) + 1.49856e-07 *lens_ipow(begin_y, 5)*begin_dx*begin_dy + 2.83668 *begin_x*lens_ipow(begin_dy, 6) + -0.000609959 *lens_ipow(begin_x, 2)*begin_y*lens_ipow(begin_dx, 3)*begin_dy + 1.56635e-09 *lens_ipow(begin_y, 6)*begin_dx*begin_lambda + -169.545 *lens_ipow(begin_dx, 5)*lens_ipow(begin_dy, 4) + -0.00861156 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 3)*lens_ipow(begin_lambda, 4) + -0.000102933 *lens_ipow(begin_y, 4)*lens_ipow(begin_dx, 5) + -0.0108939 *lens_ipow(begin_x, 2)*begin_dx*lens_ipow(begin_dy, 2)*lens_ipow(begin_lambda, 4) + -0.00316968 *lens_ipow(begin_x, 3)*lens_ipow(begin_dy, 6) + 6.981e-13 *lens_ipow(begin_x, 8)*begin_dx + -10.7066 *begin_dx*lens_ipow(begin_lambda, 10) + -0.13759 *begin_x*lens_ipow(begin_lambda, 10) + -4.87113e-14 *lens_ipow(begin_x, 5)*lens_ipow(begin_y, 4)*lens_ipow(begin_lambda, 2);
  pred_y =  + 1.32746e-06  + 81.4074 *begin_dy + 2.23125e-05 *begin_dx + 0.814303 *begin_y + 3.09328e-05 *begin_y*begin_dy + 4.08718e-07 *lens_ipow(begin_y, 2) + 1.10603e-07 *begin_x*begin_y + -68.3685 *lens_ipow(begin_dy, 3) + -67.5127 *lens_ipow(begin_dx, 2)*begin_dy + -1.36519 *begin_y*lens_ipow(begin_dy, 2) + -0.483232 *begin_y*lens_ipow(begin_dx, 2) + -0.00752916 *lens_ipow(begin_y, 2)*begin_dy + -8.08999e-06 *lens_ipow(begin_y, 3) + -0.881645 *begin_x*begin_dx*begin_dy + -0.00534004 *begin_x*begin_y*begin_dx + -0.00227046 *lens_ipow(begin_x, 2)*begin_dy + -8.25863e-06 *lens_ipow(begin_x, 2)*begin_y + 2.03969 *begin_dy*lens_ipow(begin_lambda, 3) + -0.0246183 *lens_ipow(begin_dx, 2)*lens_ipow(begin_dy, 2) + 0.000462603 *begin_y*lens_ipow(begin_dx, 3) + 16.0867 *lens_ipow(begin_dy, 5) + 0.0283785 *begin_y*lens_ipow(begin_lambda, 4) + -0.00203983 *lens_ipow(begin_y, 2)*lens_ipow(begin_dy, 3) + -0.00717656 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 2)*begin_dy + 0.00585918 *begin_x*begin_y*begin_dx*lens_ipow(begin_dy, 2) + -0.00154399 *lens_ipow(begin_x, 2)*lens_ipow(begin_dx, 2)*begin_dy + 493.201 *lens_ipow(begin_dx, 2)*lens_ipow(begin_dy, 5) + 249.213 *lens_ipow(begin_dx, 6)*begin_dy + -0.05852 *lens_ipow(begin_x, 2)*lens_ipow(begin_dy, 5) + 2.79987e-09 *lens_ipow(begin_x, 3)*lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 2) + -6.89871e-11 *lens_ipow(begin_x, 4)*lens_ipow(begin_y, 2)*begin_dy + -1.26265 *lens_ipow(begin_dx, 2)*begin_dy*lens_ipow(begin_lambda, 5) + 537.177 *lens_ipow(begin_dx, 4)*lens_ipow(begin_dy, 3)*begin_lambda + 35.0468 *begin_y*lens_ipow(begin_dx, 8) + -1.32934 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 4)*lens_ipow(begin_dy, 3) + -1.86732e-10 *lens_ipow(begin_y, 7)*lens_ipow(begin_dx, 2) + -1.05275e-13 *lens_ipow(begin_y, 8)*begin_dy + -10.8571 *begin_dy*lens_ipow(begin_lambda, 10) + -0.138546 *begin_y*lens_ipow(begin_lambda, 10) + -3.91528e-09 *lens_ipow(begin_x, 4)*lens_ipow(begin_y, 3)*lens_ipow(begin_dx, 4);
  pred_dx =  + -5.7175e-07  + -1.28923e-05 *begin_dy + 0.597374 *begin_dx + -1.88539e-07 *begin_y + -0.00629039 *begin_x + 3.30654e-06 *begin_x*begin_dx + 9.41034e-09 *begin_x*begin_y + 0.00855056 *begin_dx*lens_ipow(begin_lambda, 2) + -0.565404 *begin_dx*lens_ipow(begin_dy, 2) + -0.626716 *lens_ipow(begin_dx, 3) + -0.0223237 *begin_y*begin_dx*begin_dy + -0.000152718 *lens_ipow(begin_y, 2)*begin_dx + -0.0112216 *begin_x*lens_ipow(begin_dy, 2) + -0.0351935 *begin_x*lens_ipow(begin_dx, 2) + -0.000294575 *begin_x*begin_y*begin_dy + -2.05168e-06 *begin_x*lens_ipow(begin_y, 2) + -0.000466597 *lens_ipow(begin_x, 2)*begin_dx + 2.34311e-09 *lens_ipow(begin_x, 2)*begin_y + -2.11842e-06 *lens_ipow(begin_x, 3) + 0.000151859 *begin_y*lens_ipow(begin_dx, 2)*begin_dy + 1.59633e-10 *lens_ipow(begin_x, 4) + 0.000637011 *begin_x*lens_ipow(begin_lambda, 4) + -0.000330614 *begin_x*begin_y*lens_ipow(begin_dx, 2)*begin_dy + 0.0936617 *lens_ipow(begin_dx, 2)*lens_ipow(begin_dy, 3)*begin_lambda + 25.4122 *lens_ipow(begin_dx, 5)*lens_ipow(begin_dy, 2) + 0.00321315 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 5) + 3.34389e-11 *lens_ipow(begin_x, 5)*begin_y*begin_dy + -0.00557352 *begin_dx*lens_ipow(begin_lambda, 7) + 6.08415 *lens_ipow(begin_dx, 6)*lens_ipow(begin_dy, 2) + 0.0351916 *begin_x*lens_ipow(begin_dy, 6)*begin_lambda + 1.96011e-13 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 6)*begin_dx + -2.013e-05 *lens_ipow(begin_x, 4)*lens_ipow(begin_dx, 5) + 6.49837e-13 *lens_ipow(begin_x, 8)*begin_dx + 7.58466e-15 *lens_ipow(begin_x, 9)*begin_lambda + 8860.27 *lens_ipow(begin_dx, 5)*lens_ipow(begin_dy, 6) + 3606.96 *lens_ipow(begin_dx, 11) + -0.0026352 *begin_x*lens_ipow(begin_lambda, 10) + 4.73262e-06 *begin_x*lens_ipow(begin_y, 4)*lens_ipow(begin_dx, 4)*lens_ipow(begin_dy, 2) + -0.00021203 *lens_ipow(begin_x, 3)*begin_y*lens_ipow(begin_dx, 6)*begin_dy + -1.53611e-09 *lens_ipow(begin_x, 5)*lens_ipow(begin_lambda, 6);
  pred_dy =  + -7.19982e-07  + 0.598809 *begin_dy + 7.49901e-06 *begin_dx + -0.0062968 *begin_y + -7.54709e-07 *begin_y*begin_dy + -1.64103e-06 *begin_x*begin_dx + -9.21459e-09 *begin_x*begin_y + -0.602913 *lens_ipow(begin_dy, 3) + -0.577723 *lens_ipow(begin_dx, 2)*begin_dy + -0.0346732 *begin_y*lens_ipow(begin_dy, 2) + -0.0113786 *begin_y*lens_ipow(begin_dx, 2) + -0.000457624 *lens_ipow(begin_y, 2)*begin_dy + -2.06948e-06 *lens_ipow(begin_y, 3) + -0.0226936 *begin_x*begin_dx*begin_dy + -0.000301591 *begin_x*begin_y*begin_dx + -0.000155539 *lens_ipow(begin_x, 2)*begin_dy + -2.09377e-06 *lens_ipow(begin_x, 2)*begin_y + 1.00915e-09 *lens_ipow(begin_x, 3) + 0.000356071 *begin_y*lens_ipow(begin_lambda, 3) + 1.75353e-08 *lens_ipow(begin_y, 3)*begin_dx + -7.15571e-07 *lens_ipow(begin_x, 2)*lens_ipow(begin_dy, 2) + 1.62222e-06 *lens_ipow(begin_x, 2)*begin_dx*begin_dy + -0.000266815 *begin_x*begin_y*begin_dx*lens_ipow(begin_dy, 2) + 3.13545e-08 *begin_x*lens_ipow(begin_y, 3)*begin_dx + 8.00301e-05 *lens_ipow(begin_x, 2)*lens_ipow(begin_dy, 3) + 0.00479797 *begin_dx*lens_ipow(begin_dy, 2)*lens_ipow(begin_lambda, 3) + 0.0219136 *begin_dy*lens_ipow(begin_lambda, 6) + 0.000220987 *lens_ipow(begin_y, 3)*lens_ipow(begin_dx, 6) + -1.63196e-05 *lens_ipow(begin_y, 4)*lens_ipow(begin_dy, 5) + 2927.83 *lens_ipow(begin_dy, 11) + 28373.3 *lens_ipow(begin_dx, 4)*lens_ipow(begin_dy, 7) + 690.713 *lens_ipow(begin_dx, 10)*begin_dy + -0.00124244 *begin_y*lens_ipow(begin_lambda, 10) + 8.00771e-16 *lens_ipow(begin_y, 10)*begin_dy + 0.00271601 *begin_x*begin_dx*begin_dy*lens_ipow(begin_lambda, 8) + 0.564728 *lens_ipow(begin_x, 2)*lens_ipow(begin_dy, 9) + 0.0815725 *lens_ipow(begin_x, 2)*begin_y*lens_ipow(begin_dx, 2)*lens_ipow(begin_dy, 6) + 8.70434e-18 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 9) + -1.44097e-13 *lens_ipow(begin_x, 6)*lens_ipow(begin_y, 3)*lens_ipow(begin_dy, 2) + 5.1273e-18 *lens_ipow(begin_x, 8)*lens_ipow(begin_y, 3);
  float dx1_domega0[2][2];
  dx1_domega0[0][0] =  + 81.4095  + 0.0052412 *begin_dx + 3.14916e-05 *begin_y + -68.2088 *lens_ipow(begin_dy, 2) + -205.837 *lens_ipow(begin_dx, 2) + -0.887353 *begin_y*begin_dy + -0.00229716 *lens_ipow(begin_y, 2) + -2.74157 *begin_x*begin_dx + -0.00752169 *lens_ipow(begin_x, 2) + 2.02778 *lens_ipow(begin_lambda, 3) + 100.281 *lens_ipow(begin_dx, 4) + -0.00421329 *lens_ipow(begin_x, 2)*lens_ipow(begin_dy, 2) + -0.0115572 *lens_ipow(begin_x, 2)*lens_ipow(begin_dx, 2) + 181.368 *lens_ipow(begin_dx, 2)*lens_ipow(begin_dy, 2)*begin_lambda + -13.0132 *lens_ipow(begin_dx, 3)*lens_ipow(begin_dy, 2) + 0.0799746 *lens_ipow(begin_y, 2)*lens_ipow(begin_dy, 4) + 1.49856e-07 *lens_ipow(begin_y, 5)*begin_dy + -0.00182988 *lens_ipow(begin_x, 2)*begin_y*lens_ipow(begin_dx, 2)*begin_dy + 1.56635e-09 *lens_ipow(begin_y, 6)*begin_lambda + -847.723 *lens_ipow(begin_dx, 4)*lens_ipow(begin_dy, 4) + -0.0258347 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 2)*lens_ipow(begin_lambda, 4) + -0.000514666 *lens_ipow(begin_y, 4)*lens_ipow(begin_dx, 4) + -0.0108939 *lens_ipow(begin_x, 2)*lens_ipow(begin_dy, 2)*lens_ipow(begin_lambda, 4) + 6.981e-13 *lens_ipow(begin_x, 8) + -10.7066 *lens_ipow(begin_lambda, 10)+0.0f;
  dx1_domega0[0][1] =  + 0.000705234 *begin_dy + -136.418 *begin_dx*begin_dy + -0.887353 *begin_y*begin_dx + -0.972257 *begin_x*begin_dy + -0.00533203 *begin_x*begin_y + -9.42069e-07 *lens_ipow(begin_x, 2) + -0.00842658 *lens_ipow(begin_x, 2)*begin_dx*begin_dy + 120.912 *lens_ipow(begin_dx, 3)*begin_dy*begin_lambda + -6.5066 *lens_ipow(begin_dx, 4)*begin_dy + 0.319899 *lens_ipow(begin_y, 2)*begin_dx*lens_ipow(begin_dy, 3) + 1.49856e-07 *lens_ipow(begin_y, 5)*begin_dx + 17.0201 *begin_x*lens_ipow(begin_dy, 5) + -0.000609959 *lens_ipow(begin_x, 2)*begin_y*lens_ipow(begin_dx, 3) + -678.178 *lens_ipow(begin_dx, 5)*lens_ipow(begin_dy, 3) + -0.0217878 *lens_ipow(begin_x, 2)*begin_dx*begin_dy*lens_ipow(begin_lambda, 4) + -0.0190181 *lens_ipow(begin_x, 3)*lens_ipow(begin_dy, 5)+0.0f;
  dx1_domega0[1][0] =  + 2.23125e-05  + -135.025 *begin_dx*begin_dy + -0.966464 *begin_y*begin_dx + -0.881645 *begin_x*begin_dy + -0.00534004 *begin_x*begin_y + -0.0492365 *begin_dx*lens_ipow(begin_dy, 2) + 0.00138781 *begin_y*lens_ipow(begin_dx, 2) + -0.0143531 *lens_ipow(begin_y, 2)*begin_dx*begin_dy + 0.00585918 *begin_x*begin_y*lens_ipow(begin_dy, 2) + -0.00308797 *lens_ipow(begin_x, 2)*begin_dx*begin_dy + 986.402 *begin_dx*lens_ipow(begin_dy, 5) + 1495.28 *lens_ipow(begin_dx, 5)*begin_dy + 5.59974e-09 *lens_ipow(begin_x, 3)*lens_ipow(begin_y, 2)*begin_dx + -2.52531 *begin_dx*begin_dy*lens_ipow(begin_lambda, 5) + 2148.71 *lens_ipow(begin_dx, 3)*lens_ipow(begin_dy, 3)*begin_lambda + 280.375 *begin_y*lens_ipow(begin_dx, 7) + -5.31736 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 3)*lens_ipow(begin_dy, 3) + -3.73464e-10 *lens_ipow(begin_y, 7)*begin_dx + -1.56611e-08 *lens_ipow(begin_x, 4)*lens_ipow(begin_y, 3)*lens_ipow(begin_dx, 3)+0.0f;
  dx1_domega0[1][1] =  + 81.4074  + 3.09328e-05 *begin_y + -205.105 *lens_ipow(begin_dy, 2) + -67.5127 *lens_ipow(begin_dx, 2) + -2.73037 *begin_y*begin_dy + -0.00752916 *lens_ipow(begin_y, 2) + -0.881645 *begin_x*begin_dx + -0.00227046 *lens_ipow(begin_x, 2) + 2.03969 *lens_ipow(begin_lambda, 3) + -0.0492365 *lens_ipow(begin_dx, 2)*begin_dy + 80.4336 *lens_ipow(begin_dy, 4) + -0.00611949 *lens_ipow(begin_y, 2)*lens_ipow(begin_dy, 2) + -0.00717656 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 2) + 0.0117184 *begin_x*begin_y*begin_dx*begin_dy + -0.00154399 *lens_ipow(begin_x, 2)*lens_ipow(begin_dx, 2) + 2466 *lens_ipow(begin_dx, 2)*lens_ipow(begin_dy, 4) + 249.213 *lens_ipow(begin_dx, 6) + -0.2926 *lens_ipow(begin_x, 2)*lens_ipow(begin_dy, 4) + -6.89871e-11 *lens_ipow(begin_x, 4)*lens_ipow(begin_y, 2) + -1.26265 *lens_ipow(begin_dx, 2)*lens_ipow(begin_lambda, 5) + 1611.53 *lens_ipow(begin_dx, 4)*lens_ipow(begin_dy, 2)*begin_lambda + -3.98802 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 4)*lens_ipow(begin_dy, 2) + -1.05275e-13 *lens_ipow(begin_y, 8) + -10.8571 *lens_ipow(begin_lambda, 10)+0.0f;
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
