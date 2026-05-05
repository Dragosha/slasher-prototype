#version 140

in mediump vec2 var_texcoord0;

uniform lowp sampler2D DIFFUSE_TEXTURE;

uniform fs_uniforms
{
    lowp vec4 tint;
    lowp vec4 time;
};
out vec4 out_fragColor;

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    lowp vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    out_fragColor = texture(DIFFUSE_TEXTURE, var_texcoord0.xy) * tint_pm * time.x;
}
