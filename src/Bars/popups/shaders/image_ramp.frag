#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
	mat4 qt_Matrix;
	float qt_Opacity;
	vec4 colorDark;
	vec4 colorLight;
} ubuf;

layout(binding = 1) uniform sampler2D source;

void main() {
	// map luminance to color value
	vec4 texColor = texture(source, qt_TexCoord0);
	float luma = dot(texColor.rgb, vec3(0.299, 0.587, 0.114));
	vec3 mappedColor = mix(ubuf.colorDark.rgb, ubuf.colorLight.rgb, luma);

	// vignette
	float dist = distance(qt_TexCoord0, vec2(0.5, 0.5));
	// fades opacity from 1.0 at radius 0.3 to 0.0 at radius 0.7
	float vignette = smoothstep(0.7, 0.3, dist);

	fragColor = vec4(mappedColor * vignette, vignette) * ubuf.qt_Opacity;
}
