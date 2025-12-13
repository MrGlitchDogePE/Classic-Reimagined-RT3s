const int FOG_SHAPE_SPHERICAL = 0;
const int FOG_SHAPE_CYLINDRICAL = 1;

float getFragDistance(int fogShape, vec3 position) {
    switch (fogShape) {
        case FOG_SHAPE_SPHERICAL:
            return length(position);
        case FOG_SHAPE_CYLINDRICAL:
            return length(position);
        default:
            return length(position);
    }
}

vec4 _linearFog(vec4 fragColor, float fragDistance, vec4 fogColor, float fogStart, float fogEnd) {
#ifdef USE_FOG
    fogStart /=3;

    if (fragDistance <= fogStart) {
        return fragColor;
    }

    float factor = fragDistance < fogEnd 
        ? (fragDistance - fogStart) / (fogEnd - fogStart) 
        : 1.0;

    vec3 blended = mix(fragColor.rgb, fogColor.rgb, factor * fogColor.a);
    return vec4(blended, fragColor.a);
#else
    return fragColor;
#endif
}