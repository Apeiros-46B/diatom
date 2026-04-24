// Hald CLUT remapper. Use `lutgen generate` with --level=LUT_LEVEL option
#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
	mat4 qt_Matrix;
	float qt_Opacity;
} ubuf;

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D lut;

const float LUT_LEVEL = 16.0;

void main() {
	vec4 inputColor = texture(source, qt_TexCoord0);

	// un-premultiply alpha
	if (inputColor.a > 0.0) {
			inputColor.rgb /= inputColor.a;
	}

	float cube_size = LUT_LEVEL * LUT_LEVEL;
	float width = cube_size * LUT_LEVEL;

	// scale input color to index range [0, cube_size - 1]
	vec3 idx = floor(inputColor.rgb * (cube_size - 1.0) + 0.5);

	// map 3D color values to 2D LUT coordinates
	float x = idx.r + mod(idx.g, LUT_LEVEL) * cube_size;
	float y = idx.b * LUT_LEVEL + floor(idx.g / LUT_LEVEL);

	// map coordinates to [0, 1] with 0.5-texel offset to sample texels at center
	vec2 lutCoord = vec2(x + 0.5, y + 0.5) / width;
	vec3 mappedColor = texture(lut, lutCoord).rgb;

	// re-premultiply alpha and apply the ShaderEffect opacity
	fragColor = vec4(mappedColor * inputColor.a, inputColor.a) * ubuf.qt_Opacity;
}
