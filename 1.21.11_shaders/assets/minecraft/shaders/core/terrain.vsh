#version 460

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:chunksection.glsl>
#moj_import <minecraft:projection.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler2;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;

vec4 minecraft_sample_lightmap(sampler2D lightMap, ivec2 uv) {
    return texture(lightMap, clamp((uv / 256.0) + 0.5 / 16.0, vec2(0.5 / 16.0), vec2(15.5 / 16.0)));
}

void main() {
    vec3 pos = Position + (ChunkPosition - CameraBlockPos) + CameraOffset;
    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);

    sphericalVertexDistance = fog_spherical_distance(pos);
    cylindricalVertexDistance = fog_cylindrical_distance(pos);

    vec4 lightMapColor = minecraft_sample_lightmap(Sampler2, UV2);

    vec4 targetColor = vec4(229.0 / 255.0, 229.0 / 255.0, 229.0 / 255.0, 1.0);
    float tolerance = 0.001;
    if (all(lessThan(abs(Color - targetColor), vec4(tolerance)))) { // if nether
        vertexColor = Color * lightMapColor;
        vertexColor *= (252.0 / 229.0);
    } else {  // if overworld or end
        vertexColor = Color * lightMapColor;
    }

    texCoord0 = UV0;
}
