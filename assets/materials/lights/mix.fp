#version 140

in mediump vec2 var_texcoord0;

uniform lowp sampler2D tex0;
uniform lowp sampler2D tex1;

uniform fs_uniforms
{
    lowp vec4 mix_a;
    lowp vec4 tint0;
    lowp vec4 tint1;
};

out vec4 out_fragColor;
void main()
{
    // Pre-multiply alpha since all runtime textures already are
    vec4 tint0_pm = vec4(tint0.xyz * tint0.w, tint0.w);
    vec4 tint1_pm = vec4(tint1.xyz * tint1.w, tint1.w);

    vec4 color0 = texture(tex0, var_texcoord0.xy) * tint0_pm;
    vec4 color1 = texture(tex1, var_texcoord0.xy) * tint1_pm;
    out_fragColor = mix(color0, color1, mix_a.x);
}

