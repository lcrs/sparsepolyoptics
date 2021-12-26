#version 450

layout(lines_adjacency) in;
layout(triangle_strip, max_vertices = 4) out;

layout(location = 0) in data
{
  vec2 sensorPosVertex;
}vert[4];

out data
{
  vec2 sensorPos;
};


void main()
{
  gl_Position = gl_in[0].gl_Position;
  sensorPos = vert[0].sensorPosVertex;
  EmitVertex();
  gl_Position = gl_in[1].gl_Position;
  sensorPos = vert[1].sensorPosVertex;
  EmitVertex();
  gl_Position = gl_in[2].gl_Position;
  sensorPos = vert[2].sensorPosVertex;
  EmitVertex();
  gl_Position = gl_in[3].gl_Position;
  sensorPos = vert[3].sensorPosVertex;
  EmitVertex();

  EndPrimitive();
}
