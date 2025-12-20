#version 460

layout(std140) uniform LightmapInfo {
    float SkyFactor;
    float BlockFactor;
    float NightVisionFactor;
    float DarknessScale;
    float BossOverlayWorldDarkeningFactor;
    float BrightnessFactor;
    vec3 BlockLightTint;
    vec3 SkyLightColor;
    vec3 AmbientColor;
    vec3 NightVisionColor;
} lightmapInfo;

const int BETA_LIGHT[16] = int[](
    12, 16, 21, 26, 32, 39, 47, 56, 66, 78, 93, 111, 133, 162, 201, 255
);

const vec3 DIM_CHECK = vec3(48.0, 40.0, 33.0);

in vec2 texCoord;

out vec4 fragColor;

int spread(float f, int x) {
    return clamp(int(floor(f * float(x + 1))), 0, x);
}

void main() {
    int block_light = spread(texCoord.x, 15);
    int sky_light = spread(texCoord.y, 15);
    int sky_factor = clamp(spread(1.0 - lightmapInfo.SkyFactor, 15), 0, 11);

    int adjusted_sky = clamp(sky_light - sky_factor, 0, 15);
    int final_index = max(block_light, adjusted_sky);
    float light_factor = float(BETA_LIGHT[final_index]);

    vec3 color = vec3(light_factor / 255.0);

    // Conditional AmbientColor check
    vec3 ambientTarget = DIM_CHECK / 255.0;
    if (all(equal(lightmapInfo.AmbientColor, ambientTarget))) {
        color = mix(color, vec3(1.0 - lightmapInfo.DarknessScale), clamp(vec3(25.0 / 255.0) / 1.9, vec3(0.0), vec3(1.0)));
    }

    // Night Vision logic (revised to mix with SkyLightColor)
    if (lightmapInfo.NightVisionFactor > 0.0) {
        float max_component = max(color.r, max(color.g, color.b));
        if (max_component < 1.0) {
            vec3 bright_color = sqrt(color + lightmapInfo.SkyLightColor);
            color = mix(color, bright_color, lightmapInfo.NightVisionFactor);
        }
    }

    color = clamp(color, 0.0, 1.0);
    fragColor = pow(vec4(color, 1.0), vec4(1.0 / (1.0 + lightmapInfo.BrightnessFactor)));
}
