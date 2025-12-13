#version 330 core

#import <sodium:include/fog.glsl>
#import <sodium:include/chunk_vertex.glsl>
#import <sodium:include/chunk_matrices.glsl>
#import <sodium:include/chunk_material.glsl>

out vec4 v_Color;
out vec2 v_TexCoord;

out float v_MaterialMipBias;
#ifdef USE_FRAGMENT_DISCARD
out float v_MaterialAlphaCutoff;
#endif

#ifdef USE_FOG
out float v_FragDistance;
#endif

uniform int u_FogShape;
uniform vec3 u_RegionOffset;
uniform vec2 u_TexCoordShrink;

uniform sampler2D u_LightTex;

uvec3 _get_relative_chunk_coord(uint pos) {
    return (uvec3(pos) >> uvec3(5u, 0u, 2u)) & uvec3(7u, 3u, 7u);
}

vec3 _get_draw_translation(uint pos) {
    return vec3(16.0) * _get_relative_chunk_coord(pos);
}

void main() {
    _vert_init();

    vec3 world_pos = _vert_position + u_RegionOffset + _get_draw_translation(_draw_id);
    gl_Position = u_ProjectionMatrix * u_ModelViewMatrix * vec4(world_pos, 1.0);

#ifdef USE_FOG
    v_FragDistance = getFragDistance(u_FogShape, world_pos);
#endif

    // Vanilla-style texel center snapping (optimized)
    vec2 snapped_uv = _vert_tex_light_coord * 16.0;
    snapped_uv = (floor(snapped_uv) + 0.5) / 16.0;
    v_Color = _vert_color * texture(u_LightTex, clamp(snapped_uv, vec2(0.0), vec2(1.0)));

    // Precision fused diffuse UVs
    v_TexCoord = _vert_tex_diffuse_coord + (_vert_tex_diffuse_coord_bias * u_TexCoordShrink);

    v_MaterialMipBias = _material_mip_bias(_material_params);
#ifdef USE_FRAGMENT_DISCARD
    v_MaterialAlphaCutoff = _material_alpha_cutoff(_material_params);
#endif
}
