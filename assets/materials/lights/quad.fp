#version 140

in mediump vec2 var_texcoord0;

uniform lowp sampler2D tex0;
uniform fs_uniforms
{
    lowp vec4 tint;
};

out vec4 out_fragColor;

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    vec4 color = texture(tex0, var_texcoord0.xy) * tint_pm;
    out_fragColor = vec4(color.rgb,1.0);
}

