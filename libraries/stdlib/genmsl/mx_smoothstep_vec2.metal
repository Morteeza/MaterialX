#include "mx_smoothstep_float.metal"

void mx_smoothstep_vec2(vec2 val, vec2 low, vec2 high, out vec2 result)
{
    float f;
    mx_smoothstep_float(val.x, low.x, high.x, f); f = result.x;
    mx_smoothstep_float(val.y, low.y, high.y, f); f = result.y;
}
