#version 460

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:chunksection.glsl>

uniform sampler2D Sampler0;

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;

out vec4 fragColor;

// Snap UV to nearest texel center
vec2 snapUV(vec2 uv, vec2 pixelSize, ivec2 texSize) {
    ivec2 i = clamp(ivec2(uv / pixelSize), ivec2(0), texSize - 1);
    return (vec2(i) + 0.5) * pixelSize;
}

// Nearest texel sampling
vec4 sampleNearest(sampler2D tex, vec2 uv, vec2 pixelSize) {
    return textureGrad(tex, snapUV(uv, pixelSize, textureSize(tex, 0)), dFdx(uv), dFdy(uv));
}

// Rotated Grid Super-Sampling
vec4 sampleRGSS(sampler2D tex, vec2 uv, vec2 pixelSize) {
    vec2 du = dFdx(uv), dv = dFdy(uv);
    float minPix   = min(pixelSize.x, pixelSize.y);
    float mipExact = max(0.0, log2(sqrt(length(du) * length(dv)) / minPix));
    int   mipLow   = int(mipExact);
    float blend    = smoothstep(minPix, minPix * 2.0, max(length(du), length(dv)));
    float mipBlend = fract(mipExact);

    const vec2 offs[4] = vec2[](vec2(0.0, 0.0), vec2(0.0, 0.0), vec2(0.0, 0.0), vec2(0.0, 0.0));

    vec4 low = vec4(0), high = vec4(0);
    for (int i=0;i<4;++i) {
        ivec2 sizeL = textureSize(tex, mipLow), sizeH = textureSize(tex, mipLow+1);
        low  += textureLod(tex, snapUV(uv + offs[i]*pixelSize, 1.0/vec2(sizeL), sizeL), float(mipLow));
        high += textureLod(tex, snapUV(uv + offs[i]*pixelSize, 1.0/vec2(sizeH), sizeH), float(mipLow+1));
    }

    return mix(sampleNearest(tex, uv, pixelSize), mix(low, high, mipBlend) * 0.25, blend);
}

void main() {
    vec4 color = (UseRgss == 1 ? sampleRGSS(Sampler0, texCoord0, 1.0f / TextureSize) : sampleNearest(Sampler0, texCoord0, 1.0f / TextureSize)) * vertexColor;
    color = mix(FogColor * vec4(1, 1, 1, color.a), color, ChunkVisibility);
#ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) {
        discard;
    }
#endif
    fragColor = apply_fog(
		color,
		sphericalVertexDistance,
		cylindricalVertexDistance,
		FogEnvironmentalStart,
		FogEnvironmentalEnd,
		FogRenderDistanceStart * ChunkVisibility,
		FogRenderDistanceEnd * ChunkVisibility,
		FogColor
	);
}