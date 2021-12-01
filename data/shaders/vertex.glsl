#version 330 core
layout (location = 0) in vec3 position;
layout (location = 1) in vec4 in_color;
layout (location = 2) in vec2 in_texCoord;

out vec4 vert_color;
out vec2 vert_texCoord;

void main()
{
    gl_Position = vec4(position, 1.0);
    vert_color = in_color;
    vert_texCoord = in_texCoord;
}
