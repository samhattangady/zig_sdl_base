#version 300 es
precision mediump float;

layout(location = 0) out vec4 frag_color;

in vec4 vert_color;
in vec2 vert_texCoord;

uniform sampler2D tex;

void main()
{
    vec4 col;
    col = texture(tex, vert_texCoord.xy);
    // float bw = (vert_color.r + vert_color.g + vert_color.b) / 3;
    // frag_color = vec4(bw, bw, bw, col.r*vert_color.a);
    // frag_color = vert_color;
    frag_color = vec4(vert_color.rgb, vert_color.a*col.x);
} 
