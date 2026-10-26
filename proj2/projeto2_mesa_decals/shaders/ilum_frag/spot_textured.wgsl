struct Matrix {
  vertex: mat4x4<f32>,
  normal: mat4x4<f32>,
}
@group(1) @binding(0) var<storage, read> matrix: array<Matrix>;

struct Global {
  projection: mat4x4<f32>,
  light_ambient: vec3<f32>,
  light_diffuse: vec3<f32>,
  light_specular: vec3<f32>,
  light_position: vec4<f32>,
  spot_direction: vec3<f32>,
  spot_angle: f32,
  spot_exponent: f32,
  camera_position: vec4<f32>,
}
@group(0) @binding(0) var<uniform> global: Global;

struct Material {
  base_color: vec3<f32>,
  opacity: f32,
  specular_color: vec3<f32>,
  shininess: f32,
}
@group(2) @binding(0) var<uniform> material: Material;

@group(3) @binding(0) var decal_texture: texture_2d<f32>;
@group(3) @binding(1) var decal_sampler: sampler;

struct VertexOutput {
  @builtin(position) clip_position: vec4<f32>,
  @location(0) normal: vec3<f32>,
  @location(1) light: vec3<f32>,
  @location(2) view: vec3<f32>,
  @location(3) texcoord: vec2<f32>,
}

@vertex
fn vs_main(
  @builtin(instance_index) instance_index: u32,
  @location(0) coord: vec3<f32>,
  @location(1) normal: vec3<f32>,
  @location(2) tangent: vec3<f32>,
  @location(3) texcoord: vec2<f32>
) -> VertexOutput {
  let m = matrix[instance_index];
  let p = (m.vertex * vec4<f32>(coord, 1.0)).xyz;

  var out: VertexOutput;
  out.normal = (m.normal * vec4<f32>(normal, 0.0)).xyz;
  out.light = normalize(global.light_position.xyz - p);
  out.view = normalize(-p);
  out.texcoord = texcoord;
  out.clip_position = global.projection * vec4<f32>(p, 1.0);

  // "tangent" faz parte do formato de vértice do grafo de cena.
  // Não é necessário para um decal de cor simples.
  let _unused_tangent = tangent;

  return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
  let normal = normalize(in.normal);
  let light = normalize(in.light);
  let view = normalize(in.view);

  // Vetor -light aponta da fonte para o fragmento.
  let c = dot(-light, normalize(global.spot_direction));
  let cutoff = cos(global.spot_angle);

  var kspot = 0.0;
  if (c >= cutoff) {
    kspot = pow(max(c, 0.0), global.spot_exponent);
  }

  var color = material.base_color * global.light_ambient;

  let ndotl = dot(normal, light);
  if (ndotl > 0.0 && kspot > 0.0) {
    color += material.base_color * global.light_diffuse * ndotl * kspot;

    let refl = normalize(reflect(-light, normal));
    let spec = pow(max(0.0, dot(refl, view)), material.shininess);
    color += material.specular_color * global.light_specular * spec * kspot;
  }

  let decal = textureSample(decal_texture, decal_sampler, in.texcoord);
  return vec4<f32>(color, material.opacity) * decal;
}
