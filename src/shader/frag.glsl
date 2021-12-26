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
const float lens_outer_pupil_radius = 27.000000; // scene facing radius in mm
const float lens_inner_pupil_radius = 17.500000; // sensor facing radius in mm
const float lens_length = 91.206001; // overall lens length in mm
const float lens_focal_length = 27.871000; // approximate lens focal length in mm (BFL)
const float lens_aperture_pos = 32.044998; // distance aperture -> outer pupil in mm
const float lens_aperture_housing_radius = 12.750000; // lens housing radius at the aperture
const float lens_outer_pupil_curvature_radius = 82.059998; // radius of curvature of the outer pupil
const float lens_field_of_view = 0.904326; // cosine of the approximate field of view assuming a 35mm image
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
const float out_x =  + 49.7564 *dx + -0.45111 *x + -20.6769 *dx*lens_ipow(dy, 2) + -21.6629 *lens_ipow(dx, 3) + 0.158343 *y*dx*dy + 0.00540492 *lens_ipow(y, 2)*dx + 0.222106 *x*lens_ipow(dy, 2) + 0.325748 *x*lens_ipow(dx, 2) + 0.00588605 *x*y*dy + -0.000925557 *x*lens_ipow(y, 2) + -5.36283e-05 *lens_ipow(x, 2)*dy + 0.00983506 *lens_ipow(x, 2)*dx + -0.00105935 *lens_ipow(x, 3) + 0.327477 *x*lens_ipow(lambda, 3) + 1.70099 *x*lens_ipow(dx, 2)*lens_ipow(dy, 2) + 0.12122 *x*y*lens_ipow(dx, 2)*dy + 0.0633018 *lens_ipow(x, 2)*lens_ipow(dx, 3) + -0.000739975 *lens_ipow(x, 2)*y*dx*dy + -2.39731e-06 *lens_ipow(x, 3)*lens_ipow(y, 2) + 1.18041 *dx*lens_ipow(lambda, 5) + 110.696 *lens_ipow(dx, 3)*lens_ipow(dy, 4) + 96.7428 *lens_ipow(dx, 5)*lens_ipow(dy, 2) + 9.06136 *y*lens_ipow(dx, 3)*lens_ipow(dy, 3) + 0.000325898 *lens_ipow(y, 4)*dx*lens_ipow(dy, 2) + 4.44507 *x*lens_ipow(dx, 6) + -2.32777e-06 *x*lens_ipow(y, 4)*lens_ipow(dx, 2) + -4.70583e-09 *x*lens_ipow(y, 6) + 0.128422 *lens_ipow(x, 2)*dx*lens_ipow(dy, 4) + -1.07901e-07 *lens_ipow(x, 3)*lens_ipow(y, 3)*dy + 135.504 *lens_ipow(dx, 9) + 0.182121 *x*y*lens_ipow(dy, 7) + -1.3638 *x*y*lens_ipow(dx, 6)*dy + 2.81704e-08 *lens_ipow(x, 6)*y*dx*dy + -8.89741e-12 *lens_ipow(x, 9) + 5.31622e-06 *lens_ipow(x, 3)*lens_ipow(y, 2)*lens_ipow(lambda, 5) + 2.12111e-06 *lens_ipow(x, 5)*lens_ipow(lambda, 5) + -2.09036 *x*lens_ipow(lambda, 10) + 7.36595e-09 *x*lens_ipow(y, 6)*lens_ipow(lambda, 4) + 0.0427966 *lens_ipow(x, 3)*lens_ipow(dy, 8) + -1.69756e-13 *lens_ipow(x, 7)*lens_ipow(y, 4);
const float out_y =  + -0.000255832  + 49.7076 *dy + -0.450998 *y + -21.7135 *lens_ipow(dy, 3) + -20.4721 *lens_ipow(dx, 2)*dy + 0.302858 *y*lens_ipow(dy, 2) + 0.213691 *y*lens_ipow(dx, 2) + 0.0108702 *lens_ipow(y, 2)*dy + -0.00104189 *lens_ipow(y, 3) + 0.015897 *x*dx*dy + 0.00801017 *x*y*dx + 0.0057819 *lens_ipow(x, 2)*dy + -0.000902567 *lens_ipow(x, 2)*y + 0.324104 *y*lens_ipow(lambda, 3) + 2.21888 *y*lens_ipow(dx, 2)*lens_ipow(dy, 2) + 0.0695908 *lens_ipow(y, 2)*lens_ipow(dy, 3) + 0.0258353 *lens_ipow(y, 2)*lens_ipow(dx, 2)*dy + 1.55083 *x*dx*lens_ipow(dy, 3) + 0.908841 *x*lens_ipow(dx, 3)*dy + 0.120406 *x*y*dx*lens_ipow(dy, 2) + -2.19662e-05 *x*lens_ipow(y, 3)*dx + -1.73418e-05 *lens_ipow(x, 2)*lens_ipow(y, 2)*dy + -2.89843e-06 *lens_ipow(x, 2)*lens_ipow(y, 3) + 1.24163 *dy*lens_ipow(lambda, 5) + 107.925 *lens_ipow(dx, 2)*lens_ipow(dy, 5) + 6.00743 *y*lens_ipow(dy, 6) + 0.259702 *lens_ipow(x, 2)*lens_ipow(dx, 2)*lens_ipow(dy, 3) + 0.000217323 *lens_ipow(x, 4)*lens_ipow(dx, 2)*dy + -2.49488e-06 *lens_ipow(x, 4)*y*lens_ipow(dy, 2) + -4.30424e-09 *lens_ipow(x, 6)*y + -7.24959e-08 *lens_ipow(y, 6)*dy*lambda + -1.60675e-07 *lens_ipow(x, 5)*y*dx*lambda + 180.736 *lens_ipow(dy, 9) + 559.347 *lens_ipow(dx, 6)*lens_ipow(dy, 3) + 0.00652117 *lens_ipow(y, 3)*lens_ipow(dx, 6) + -9.80955e-12 *lens_ipow(y, 9) + 1.55747e-06 *lens_ipow(y, 5)*lens_ipow(lambda, 5) + 7.24298e-06 *lens_ipow(x, 2)*lens_ipow(y, 3)*lens_ipow(lambda, 5) + -2.0189 *y*lens_ipow(lambda, 10) + -1.44756e-13 *lens_ipow(x, 4)*lens_ipow(y, 7);
const float out_dx =  + -0.606975 *dx + -0.0145462 *x + 0.139926 *dx*lens_ipow(dy, 2) + 0.230118 *lens_ipow(dx, 3) + -2.07783e-05 *lens_ipow(y, 2)*dx + -0.00205951 *x*lens_ipow(dy, 2) + -7.26889e-05 *x*y*dy + 1.41104e-05 *x*lens_ipow(y, 2) + 8.55275e-07 *lens_ipow(x, 2)*dy + -0.000173851 *lens_ipow(x, 2)*dx + 1.48755e-05 *lens_ipow(x, 3) + 0.00836381 *dx*lens_ipow(lambda, 3) + -0.00396337 *x*lens_ipow(lambda, 3) + -0.00373205 *y*dx*lens_ipow(dy, 3) + 0.000502111 *lens_ipow(y, 2)*lens_ipow(dx, 3) + 9.26121e-06 *lens_ipow(y, 3)*dx*dy + 9.97091e-06 *x*lens_ipow(y, 2)*lens_ipow(dy, 2) + 0.000797347 *lens_ipow(x, 2)*dx*lens_ipow(dy, 2) + 0.00100591 *lens_ipow(x, 2)*lens_ipow(dx, 3) + 4.51109e-05 *lens_ipow(x, 2)*y*dx*dy + 0.000397738 *lens_ipow(y, 2)*dx*lens_ipow(dy, 2)*lambda + 0.00300325 *x*y*lens_ipow(dx, 4)*dy + 5.05889e-11 *x*lens_ipow(y, 6) + -1.96342e-09 *lens_ipow(x, 3)*lens_ipow(y, 3)*dy + 1.15027e-08 *lens_ipow(x, 5)*lens_ipow(dy, 2) + 1.40363e-10 *lens_ipow(x, 5)*lens_ipow(y, 2) + 0.0197082 *x*y*lens_ipow(dx, 2)*lens_ipow(dy, 5) + -3.53468e-08 *x*lens_ipow(y, 4)*lens_ipow(lambda, 4) + 1.18601e-05 *lens_ipow(x, 3)*y*lens_ipow(dy, 5) + -3.43286e-08 *lens_ipow(x, 3)*lens_ipow(y, 3)*lens_ipow(dx, 2)*dy + -1.33797e-09 *lens_ipow(x, 4)*lens_ipow(y, 3)*dx*dy + -1.23413e-11 *lens_ipow(x, 4)*lens_ipow(y, 4)*dx + -2.3465e-08 *lens_ipow(x, 5)*lens_ipow(lambda, 4) + 6.38451e-07 *lens_ipow(x, 5)*lens_ipow(dx, 4) + -8.87159e-14 *lens_ipow(x, 8)*dx + 1.06211e-13 *lens_ipow(x, 9) + -0.0100529 *lens_ipow(y, 2)*lens_ipow(dx, 9) + 0.0267101 *x*lens_ipow(lambda, 10) + -2.41143e-10 *lens_ipow(x, 5)*lens_ipow(y, 2)*lens_ipow(lambda, 4) + 1.90932e-15 *lens_ipow(x, 5)*lens_ipow(y, 6);
const float out_dy =  + -0.60801 *dy + -0.0145595 *y + 0.245273 *lens_ipow(dy, 3) + 0.340909 *lens_ipow(dx, 2)*dy + -0.00316616 *y*lens_ipow(dx, 2) + -0.000146289 *lens_ipow(y, 2)*dy + 1.46753e-05 *lens_ipow(y, 3) + 0.00366858 *x*dx*dy + 1.27108e-06 *x*y*dy + -0.000104641 *x*y*dx + -7.15018e-05 *lens_ipow(x, 2)*dy + 1.44672e-05 *lens_ipow(x, 2)*y + 0.00907091 *dy*lens_ipow(lambda, 3) + -0.00396412 *y*lens_ipow(lambda, 3) + -0.00494909 *y*lens_ipow(dy, 4) + 0.000699533 *lens_ipow(y, 2)*lens_ipow(dy, 3) + 0.000640118 *lens_ipow(y, 2)*lens_ipow(dx, 2)*dy + 1.61632e-05 *lens_ipow(y, 3)*lens_ipow(dy, 2) + -5.75462e-06 *lens_ipow(y, 3)*lens_ipow(dx, 2) + 1.98884e-05 *x*lens_ipow(y, 2)*dx*dy + 0.000390291 *lens_ipow(x, 2)*lens_ipow(dy, 3) + 0.000513272 *lens_ipow(x, 2)*lens_ipow(dx, 2)*dy + -1.26957 *lens_ipow(dx, 2)*lens_ipow(dy, 5) + -0.552499 *lens_ipow(dx, 6)*dy + -5.22358e-05 *lens_ipow(y, 3)*lens_ipow(dx, 2)*lens_ipow(dy, 2) + 0.000773701 *x*y*lens_ipow(dx, 5) + -4.78825e-07 *lens_ipow(x, 2)*lens_ipow(y, 2)*lens_ipow(dx, 2)*dy + 1.30194e-10 *lens_ipow(x, 2)*lens_ipow(y, 5) + -5.9889e-10 *lens_ipow(x, 4)*lens_ipow(y, 2)*dy + 1.05778e-10 *lens_ipow(x, 4)*lens_ipow(y, 3) + 4.31434e-11 *lens_ipow(x, 6)*y + -0.944 *lens_ipow(dy, 9) + 1.34112e-13 *lens_ipow(y, 8)*dy + 1.12022e-13 *lens_ipow(y, 9) + 0.037083 *x*y*lens_ipow(dx, 3)*lens_ipow(dy, 4) + 6.02163e-08 *lens_ipow(x, 2)*lens_ipow(y, 2)*lens_ipow(dy, 3)*lens_ipow(lambda, 2) + -2.28647e-08 *lens_ipow(x, 4)*y*lens_ipow(lambda, 4) + -3.25635e-08 *lens_ipow(y, 5)*lens_ipow(lambda, 5) + -7.83448e-08 *lens_ipow(x, 2)*lens_ipow(y, 3)*lens_ipow(lambda, 5) + 0.0273724 *y*lens_ipow(lambda, 10);
const float out_transmittance =  + 0.333512  + 0.280781 *lambda + -2.84678e-06 *dy + -1.75985e-06 *dx + -0.027121 *lens_ipow(dy, 2) + -0.0321791 *lens_ipow(dx, 2) + -0.000337427 *y*dy + -6.6444e-06 *lens_ipow(y, 2) + -0.00038847 *x*dx + -1.35534e-05 *lens_ipow(x, 2) + -0.232101 *lens_ipow(lambda, 3) + -0.0068813 *y*lens_ipow(dy, 3) + -0.00592774 *y*lens_ipow(dx, 2)*dy + -0.000324577 *lens_ipow(y, 2)*lens_ipow(dy, 2) + -7.56e-07 *lens_ipow(y, 3)*dy + -0.00595613 *x*dx*lens_ipow(dy, 2) + -0.00731768 *x*lens_ipow(dx, 3) + -0.000428208 *x*y*dx*dy + 1.60803e-06 *lens_ipow(x, 3)*dx + -0.554329 *lens_ipow(dy, 6) + -1.60078 *lens_ipow(dx, 2)*lens_ipow(dy, 4) + -1.40849 *lens_ipow(dx, 4)*lens_ipow(dy, 2) + -0.435074 *lens_ipow(dx, 6) + -0.000536006 *lens_ipow(y, 2)*lens_ipow(dx, 4) + -1.00769e-10 *lens_ipow(y, 6) + -1.10344e-09 *x*lens_ipow(y, 4)*dx + -0.000422882 *lens_ipow(x, 2)*lens_ipow(dy, 4) + -0.00174843 *lens_ipow(x, 2)*lens_ipow(dx, 4) + 1.33592e-05 *lens_ipow(x, 2)*y*lens_ipow(dy, 3) + -1.19874e-08 *lens_ipow(x, 2)*lens_ipow(y, 3)*dy + -6.00719e-09 *lens_ipow(x, 3)*lens_ipow(y, 2)*dx + -6.69678e-10 *lens_ipow(y, 6)*lens_ipow(dx, 2) + -1.9219e-05 *lens_ipow(x, 2)*lens_ipow(y, 2)*lens_ipow(dx, 2)*lens_ipow(dy, 2) + -2.16786e-12 *lens_ipow(x, 2)*lens_ipow(y, 6) + 7.41756e-06 *lens_ipow(x, 3)*y*dx*lens_ipow(dy, 3) + 4.20386e-12 *lens_ipow(x, 6)*y*dy + -2.30144e-12 *lens_ipow(x, 6)*lens_ipow(y, 2) + -0.749088 *lens_ipow(dx, 2)*lens_ipow(dy, 2)*lens_ipow(lambda, 5) + 4.60504e-10 *lens_ipow(x, 7)*dx*lens_ipow(dy, 2) + 0.42002 *lens_ipow(lambda, 11);
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
  pred_x =  + 0.000133162  + 28.4765 *begin_dx + 3.05378e-05 *begin_y + 0.224951 *begin_x + -15.2544 *begin_dx*lens_ipow(begin_dy, 2) + -14.761 *lens_ipow(begin_dx, 3) + -0.0193266 *begin_y*begin_dx*begin_dy + 0.00177015 *lens_ipow(begin_y, 2)*begin_dx + -0.144064 *begin_x*lens_ipow(begin_dy, 2) + -0.169814 *begin_x*lens_ipow(begin_dx, 2) + 0.000691894 *begin_x*begin_y*begin_dy + -0.000323112 *begin_x*lens_ipow(begin_y, 2) + 0.00197424 *lens_ipow(begin_x, 2)*begin_dx + -0.000442341 *lens_ipow(begin_x, 3) + 0.142358 *begin_x*lens_ipow(begin_lambda, 3) + 5.00588 *begin_dx*lens_ipow(begin_lambda, 4) + 0.0136947 *lens_ipow(begin_y, 2)*begin_dx*lens_ipow(begin_dy, 2) + -0.013911 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 3) + -2.03396e-05 *begin_x*lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 2) + -7.21627e-07 *begin_x*lens_ipow(begin_y, 4) + -0.0228744 *lens_ipow(begin_x, 2)*begin_dx*lens_ipow(begin_dy, 2) + -0.000604134 *lens_ipow(begin_x, 2)*begin_y*begin_dx*begin_dy + -1.09384e-06 *lens_ipow(begin_x, 3)*lens_ipow(begin_y, 2) + 18.3921 *begin_dx*lens_ipow(begin_dy, 6) + 26.9161 *lens_ipow(begin_dx, 5)*lens_ipow(begin_dy, 2) + -0.825892 *begin_y*lens_ipow(begin_dx, 5)*begin_dy + 0.626384 *begin_x*lens_ipow(begin_dy, 6) + 9.92965e-05 *begin_x*lens_ipow(begin_y, 3)*lens_ipow(begin_dx, 2)*begin_dy + -7.31158e-05 *lens_ipow(begin_x, 3)*begin_y*lens_ipow(begin_dy, 3) + 0.000179573 *lens_ipow(begin_x, 3)*begin_y*lens_ipow(begin_dx, 2)*begin_dy + 2.40165e-08 *lens_ipow(begin_x, 6)*begin_dx + -1.81124e-08 *lens_ipow(begin_x, 5)*lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 2) + -3.59711e-12 *lens_ipow(begin_x, 9) + 2.9326e-06 *lens_ipow(begin_x, 3)*lens_ipow(begin_y, 2)*lens_ipow(begin_lambda, 5) + 7.15746e-07 *lens_ipow(begin_x, 5)*lens_ipow(begin_lambda, 5) + -24.5287 *begin_dx*lens_ipow(begin_lambda, 10) + 0.416595 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 9) + -0.905518 *begin_x*lens_ipow(begin_lambda, 10) + -9.80573e-11 *lens_ipow(begin_x, 7)*lens_ipow(begin_y, 2)*lens_ipow(begin_dy, 2) + -6.90883e-14 *lens_ipow(begin_x, 7)*lens_ipow(begin_y, 4);
  pred_y =  + -0.000167627  + 28.51 *begin_dy + 0.218098 *begin_y + -15.1993 *lens_ipow(begin_dy, 3) + -14.9868 *lens_ipow(begin_dx, 2)*begin_dy + -0.132441 *begin_y*lens_ipow(begin_dy, 2) + -0.118281 *begin_y*lens_ipow(begin_dx, 2) + 0.0019477 *lens_ipow(begin_y, 2)*begin_dy + -0.000285856 *lens_ipow(begin_y, 3) + -0.0318129 *begin_x*begin_dx*begin_dy + 0.000305241 *begin_x*begin_y*begin_dx + 0.00138375 *lens_ipow(begin_x, 2)*begin_dy + -0.000282321 *lens_ipow(begin_x, 2)*begin_y + 0.138185 *begin_y*lens_ipow(begin_lambda, 3) + 4.95146 *begin_dy*lens_ipow(begin_lambda, 4) + -0.0123287 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 2)*begin_dy + -0.000484739 *lens_ipow(begin_y, 3)*lens_ipow(begin_dy, 2) + -7.28209e-05 *lens_ipow(begin_y, 3)*lens_ipow(begin_dx, 2) + -7.69732e-07 *lens_ipow(begin_y, 5) + 0.0277696 *begin_x*begin_y*begin_dx*lens_ipow(begin_dy, 2) + -0.00759786 *lens_ipow(begin_x, 2)*lens_ipow(begin_dy, 3) + 0.0101379 *lens_ipow(begin_x, 2)*lens_ipow(begin_dx, 2)*begin_dy + -0.000136452 *lens_ipow(begin_x, 2)*begin_y*lens_ipow(begin_dy, 2) + -0.000396579 *lens_ipow(begin_x, 2)*begin_y*lens_ipow(begin_dx, 2) + -1.45812e-06 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 3) + -7.63511e-07 *lens_ipow(begin_x, 4)*begin_y + 2.29254 *begin_y*lens_ipow(begin_dx, 4)*lens_ipow(begin_dy, 2) + -0.0554698 *begin_x*begin_y*lens_ipow(begin_dx, 5) + -3.57544e-06 *lens_ipow(begin_x, 3)*lens_ipow(begin_y, 2)*begin_dx*begin_dy + 34.588 *lens_ipow(begin_dy, 9) + 473.18 *lens_ipow(begin_dx, 4)*lens_ipow(begin_dy, 5) + 5.80021e-07 *lens_ipow(begin_y, 5)*lens_ipow(begin_lambda, 4) + -8.14537e-08 *lens_ipow(begin_y, 6)*lens_ipow(begin_dx, 2)*begin_dy + 8.97575e-07 *begin_x*lens_ipow(begin_y, 5)*begin_dx*lens_ipow(begin_dy, 2) + 2.90358e-06 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 3)*lens_ipow(begin_lambda, 5) + -24.1953 *begin_dy*lens_ipow(begin_lambda, 10) + -0.868843 *begin_y*lens_ipow(begin_lambda, 10) + -9.02301e-12 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 7)*lens_ipow(begin_dx, 2) + 8.33492e-13 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 8)*begin_dy + -4.6423e-14 *lens_ipow(begin_x, 4)*lens_ipow(begin_y, 7);
  pred_dx =  + -2.59688e-06  + 0.398332 *begin_dx + -0.0317262 *begin_x + -0.498095 *begin_dx*lens_ipow(begin_dy, 2) + -0.489773 *lens_ipow(begin_dx, 3) + -0.0201563 *begin_y*begin_dx*begin_dy + -2.33164e-05 *lens_ipow(begin_y, 2)*begin_dx + -0.0108622 *begin_x*lens_ipow(begin_dy, 2) + -0.0313598 *begin_x*lens_ipow(begin_dx, 2) + 0.000269457 *begin_x*begin_y*begin_dy + 3.19288e-06 *begin_x*begin_y*begin_dx + -2.94324e-05 *begin_x*lens_ipow(begin_y, 2) + 0.000292095 *lens_ipow(begin_x, 2)*begin_dx + -2.85278e-05 *lens_ipow(begin_x, 3) + 0.00776112 *begin_x*lens_ipow(begin_lambda, 3) + -0.0639612 *begin_y*lens_ipow(begin_dx, 5)*begin_dy + -0.000245653 *lens_ipow(begin_y, 3)*begin_dx*lens_ipow(begin_dy, 3) + -0.0017583 *begin_x*begin_y*lens_ipow(begin_dy, 5) + 1.19995e-08 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 4)*begin_dx + 2.14673e-05 *lens_ipow(begin_x, 3)*lens_ipow(begin_dy, 4) + -3.31283e-07 *lens_ipow(begin_x, 3)*lens_ipow(begin_y, 2)*lens_ipow(begin_dy, 2) + 4.74379e-09 *lens_ipow(begin_x, 5)*begin_y*begin_dy + 1.24161e-07 *lens_ipow(begin_x, 3)*lens_ipow(begin_y, 2)*lens_ipow(begin_lambda, 3) + 5.34326e-12 *lens_ipow(begin_y, 8)*begin_dx + 4.36316e-08 *begin_x*lens_ipow(begin_y, 4)*lens_ipow(begin_lambda, 4) + -9.31635e-07 *begin_x*lens_ipow(begin_y, 4)*lens_ipow(begin_dx, 4) + 2.99453e-11 *begin_x*lens_ipow(begin_y, 7)*begin_dy + 1.9587e-07 *lens_ipow(begin_x, 3)*lens_ipow(begin_y, 3)*lens_ipow(begin_dx, 2)*begin_dy + 5.74778e-08 *lens_ipow(begin_x, 4)*lens_ipow(begin_y, 2)*begin_dx*lens_ipow(begin_dy, 2) + 4.99963e-08 *lens_ipow(begin_x, 5)*lens_ipow(begin_lambda, 4) + -4.30676e-09 *lens_ipow(begin_x, 5)*lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 2) + -2.16997e-12 *lens_ipow(begin_x, 5)*lens_ipow(begin_y, 4) + -3.11511e-10 *lens_ipow(begin_x, 7)*lens_ipow(begin_dy, 2) + 1.97622e-11 *lens_ipow(begin_x, 8)*begin_dx + -1.66835e-13 *lens_ipow(begin_x, 9) + -1.25697e-06 *lens_ipow(begin_x, 4)*begin_dx*lens_ipow(begin_lambda, 5) + -0.053819 *begin_x*lens_ipow(begin_lambda, 10) + -3.04123e-15 *lens_ipow(begin_x, 3)*lens_ipow(begin_y, 8) + 2.12628e-07 *lens_ipow(begin_x, 6)*lens_ipow(begin_dx, 5) + -2.41787e-15 *lens_ipow(begin_x, 9)*lens_ipow(begin_y, 2);
  pred_dy =  + 0.400049 *begin_dy + -0.0318898 *begin_y + -0.511767 *lens_ipow(begin_dy, 3) + -0.507283 *lens_ipow(begin_dx, 2)*begin_dy + -0.0308361 *begin_y*lens_ipow(begin_dy, 2) + -0.0111372 *begin_y*lens_ipow(begin_dx, 2) + 0.000281704 *lens_ipow(begin_y, 2)*begin_dy + -2.68682e-05 *lens_ipow(begin_y, 3) + -0.0197581 *begin_x*begin_dx*begin_dy + 0.000239951 *begin_x*begin_y*begin_dx + 2.13629e-07 *lens_ipow(begin_x, 2)*begin_dy + -2.47889e-05 *lens_ipow(begin_x, 2)*begin_y + 0.00769775 *begin_y*lens_ipow(begin_lambda, 3) + 0.0014548 *begin_x*begin_y*begin_dx*lens_ipow(begin_dy, 2) + 1.94746 *lens_ipow(begin_dx, 2)*lens_ipow(begin_dy, 5) + 0.0825923 *begin_y*lens_ipow(begin_dx, 4)*lens_ipow(begin_dy, 2) + -1.00726e-07 *begin_x*lens_ipow(begin_y, 4)*begin_dx*begin_dy + -0.000120201 *lens_ipow(begin_x, 2)*begin_dy*lens_ipow(begin_lambda, 4) + 0.00505395 *lens_ipow(begin_x, 2)*lens_ipow(begin_dx, 4)*begin_dy + -7.61297e-07 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 3)*lens_ipow(begin_dy, 2) + -4.46652e-10 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 5) + 1.34304e-08 *lens_ipow(begin_x, 3)*lens_ipow(begin_y, 3)*begin_dx + -1.90848e-07 *lens_ipow(begin_x, 4)*begin_y*lens_ipow(begin_dx, 2) + 1.07419e-08 *lens_ipow(begin_x, 4)*lens_ipow(begin_y, 2)*begin_dy + -1.09467e-07 *lens_ipow(begin_x, 5)*begin_dx*begin_dy + -1.23958e-10 *lens_ipow(begin_x, 6)*begin_y + 1.66098e-07 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 3)*lens_ipow(begin_lambda, 3) + 0.0597836 *begin_y*lens_ipow(begin_dx, 8) + -3.85451e-10 *lens_ipow(begin_y, 7)*lens_ipow(begin_dx, 2) + 2.18357e-11 *lens_ipow(begin_y, 8)*begin_dy + -1.86349e-13 *lens_ipow(begin_y, 9) + 5.75469e-08 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 4)*lens_ipow(begin_dx, 2)*begin_dy + 6.69337e-09 *lens_ipow(begin_x, 6)*lens_ipow(begin_dy, 3) + -1.32823e-06 *lens_ipow(begin_y, 4)*begin_dy*lens_ipow(begin_lambda, 5) + 4.21842 *lens_ipow(begin_dy, 11) + -0.0510611 *begin_y*lens_ipow(begin_lambda, 10) + 2.4985e-07 *lens_ipow(begin_y, 6)*lens_ipow(begin_dy, 5) + 1.77233e-10 *lens_ipow(begin_y, 7)*lens_ipow(begin_lambda, 4) + 3.12852e-14 *begin_x*lens_ipow(begin_y, 9)*begin_dx + -5.34675e-15 *lens_ipow(begin_x, 6)*lens_ipow(begin_y, 5);
  float dx1_domega0[2][2];
  dx1_domega0[0][0] =  + 28.4765  + -15.2544 *lens_ipow(begin_dy, 2) + -44.2829 *lens_ipow(begin_dx, 2) + -0.0193266 *begin_y*begin_dy + 0.00177015 *lens_ipow(begin_y, 2) + -0.339629 *begin_x*begin_dx + 0.00197424 *lens_ipow(begin_x, 2) + 5.00588 *lens_ipow(begin_lambda, 4) + 0.0136947 *lens_ipow(begin_y, 2)*lens_ipow(begin_dy, 2) + -0.0417331 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 2) + -4.06793e-05 *begin_x*lens_ipow(begin_y, 2)*begin_dx + -0.0228744 *lens_ipow(begin_x, 2)*lens_ipow(begin_dy, 2) + -0.000604134 *lens_ipow(begin_x, 2)*begin_y*begin_dy + 18.3921 *lens_ipow(begin_dy, 6) + 134.581 *lens_ipow(begin_dx, 4)*lens_ipow(begin_dy, 2) + -4.12946 *begin_y*lens_ipow(begin_dx, 4)*begin_dy + 0.000198593 *begin_x*lens_ipow(begin_y, 3)*begin_dx*begin_dy + 0.000359145 *lens_ipow(begin_x, 3)*begin_y*begin_dx*begin_dy + 2.40165e-08 *lens_ipow(begin_x, 6) + -3.62248e-08 *lens_ipow(begin_x, 5)*lens_ipow(begin_y, 2)*begin_dx + -24.5287 *lens_ipow(begin_lambda, 10) + 3.74936 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 8)+0.0f;
  dx1_domega0[0][1] =  + -30.5087 *begin_dx*begin_dy + -0.0193266 *begin_y*begin_dx + -0.288129 *begin_x*begin_dy + 0.000691894 *begin_x*begin_y + 0.0273893 *lens_ipow(begin_y, 2)*begin_dx*begin_dy + -0.0457489 *lens_ipow(begin_x, 2)*begin_dx*begin_dy + -0.000604134 *lens_ipow(begin_x, 2)*begin_y*begin_dx + 110.353 *begin_dx*lens_ipow(begin_dy, 5) + 53.8323 *lens_ipow(begin_dx, 5)*begin_dy + -0.825892 *begin_y*lens_ipow(begin_dx, 5) + 3.7583 *begin_x*lens_ipow(begin_dy, 5) + 9.92965e-05 *begin_x*lens_ipow(begin_y, 3)*lens_ipow(begin_dx, 2) + -0.000219347 *lens_ipow(begin_x, 3)*begin_y*lens_ipow(begin_dy, 2) + 0.000179573 *lens_ipow(begin_x, 3)*begin_y*lens_ipow(begin_dx, 2) + -1.96115e-10 *lens_ipow(begin_x, 7)*lens_ipow(begin_y, 2)*begin_dy+0.0f;
  dx1_domega0[1][0] =  + -29.9736 *begin_dx*begin_dy + -0.236561 *begin_y*begin_dx + -0.0318129 *begin_x*begin_dy + 0.000305241 *begin_x*begin_y + -0.0246573 *lens_ipow(begin_y, 2)*begin_dx*begin_dy + -0.000145642 *lens_ipow(begin_y, 3)*begin_dx + 0.0277696 *begin_x*begin_y*lens_ipow(begin_dy, 2) + 0.0202758 *lens_ipow(begin_x, 2)*begin_dx*begin_dy + -0.000793157 *lens_ipow(begin_x, 2)*begin_y*begin_dx + 9.17015 *begin_y*lens_ipow(begin_dx, 3)*lens_ipow(begin_dy, 2) + -0.277349 *begin_x*begin_y*lens_ipow(begin_dx, 4) + -3.57544e-06 *lens_ipow(begin_x, 3)*lens_ipow(begin_y, 2)*begin_dy + 1892.72 *lens_ipow(begin_dx, 3)*lens_ipow(begin_dy, 5) + -1.62907e-07 *lens_ipow(begin_y, 6)*begin_dx*begin_dy + 8.97575e-07 *begin_x*lens_ipow(begin_y, 5)*lens_ipow(begin_dy, 2) + -1.8046e-11 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 7)*begin_dx+0.0f;
  dx1_domega0[1][1] =  + 28.51  + -45.5979 *lens_ipow(begin_dy, 2) + -14.9868 *lens_ipow(begin_dx, 2) + -0.264882 *begin_y*begin_dy + 0.0019477 *lens_ipow(begin_y, 2) + -0.0318129 *begin_x*begin_dx + 0.00138375 *lens_ipow(begin_x, 2) + 4.95146 *lens_ipow(begin_lambda, 4) + -0.0123287 *lens_ipow(begin_y, 2)*lens_ipow(begin_dx, 2) + -0.000969478 *lens_ipow(begin_y, 3)*begin_dy + 0.0555393 *begin_x*begin_y*begin_dx*begin_dy + -0.0227936 *lens_ipow(begin_x, 2)*lens_ipow(begin_dy, 2) + 0.0101379 *lens_ipow(begin_x, 2)*lens_ipow(begin_dx, 2) + -0.000272903 *lens_ipow(begin_x, 2)*begin_y*begin_dy + 4.58508 *begin_y*lens_ipow(begin_dx, 4)*begin_dy + -3.57544e-06 *lens_ipow(begin_x, 3)*lens_ipow(begin_y, 2)*begin_dx + 311.292 *lens_ipow(begin_dy, 8) + 2365.9 *lens_ipow(begin_dx, 4)*lens_ipow(begin_dy, 4) + -8.14537e-08 *lens_ipow(begin_y, 6)*lens_ipow(begin_dx, 2) + 1.79515e-06 *begin_x*lens_ipow(begin_y, 5)*begin_dx*begin_dy + -24.1953 *lens_ipow(begin_lambda, 10) + 8.33492e-13 *lens_ipow(begin_x, 2)*lens_ipow(begin_y, 8)+0.0f;
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
