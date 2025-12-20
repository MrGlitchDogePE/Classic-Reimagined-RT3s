#version 460

layout(std140) uniform LightmapInfo {
    float AmbientLightFactor;
    float SkyFactor;
    float BlockFactor;
    float NightVisionFactor;
    float DarknessScale;
    float DarkenWorldFactor;
    float BrightnessFactor;
    vec3 SkyLightColor;
    vec3 AmbientColor;
} lightmapInfo;

const int BETA_LIGHT[16] = int[](
    12, 16, 21, 26, 32, 39, 47, 56, 66, 78, 93, 111, 133, 162, 201, 255
);

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
    float light_factor = BETA_LIGHT[final_index];

    vec3 color = vec3(light_factor / 255.0);

    // Keep Ambient Color and Ambient Light as-is
    color = mix(color, lightmapInfo.AmbientColor, clamp(lightmapInfo.AmbientLightFactor / 1.9, 0.0, 1.0));

    // Night Vision logic (revised to mix with SkyLightColor)
    // Minecraft 1.21.9 and above are required
    if (lightmapInfo.NightVisionFactor > 0.0) {
        float max_component = max(color.r, max(color.g, color.b));
        if (max_component < 1.0) {
            vec3 bright_color = sqrt(1 - (sqrt(1 / (lightmapInfo.AmbientColor)) - color));
            color = mix(color, sqrt(bright_color), lightmapInfo.NightVisionFactor);
        }
    }

    color = clamp(color, 0.0, 1.0);
    fragColor = pow(vec4(color, 1.0), vec4(1.0 / (1.0 + lightmapInfo.BrightnessFactor)));
}
