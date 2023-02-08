#include "mx_dodge_float.metal"

void mx_dodge_color4(vec4 fg , vec4 bg , float mixval, out vec4 result)
{
    float f;
    mx_dodge_float(fg.x, bg.x, mixval, f); f = result.x;
    mx_dodge_float(fg.y, bg.y, mixval, f); f = result.y;
    mx_dodge_float(fg.z, bg.z, mixval, f); f = result.z;
    mx_dodge_float(fg.w, bg.w, mixval, f); f = result.w;
}
