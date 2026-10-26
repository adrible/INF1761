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

  // Fog linear
  fog_color: vec3<f32>,
  fog_near: f32,
  fog_far: f32,
}
@group(0) @binding(0) var<uniform> global: Global;

struct Material {
  base_color: vec3<f32>,
  opacity: f32,
  specular_color: vec3<f32>,
  shininess: f32,
}
@group(2) @binding(0) var<uniform> material: Material;

struct VertexOutput {
  @builtin(position) clip_position: vec4<f32>,
  @location(0) normal: vec3<f32>,
  @location(1) light: vec3<f32>,
  @location(2) view: vec3<f32>,
  @location(3) fog_distance: f32,
}

@vertex
fn vs_main(
  @builtin(instance_index) instance_index: u32,
  @location(0) coord: vec3<f32>,
  @location(1) normal: vec3<f32>
) -> VertexOutput {
  let m = matrix[instance_index];
  let p = (m.vertex * vec4<f32>(coord, 1.0)).xyz;

  var out: VertexOutput;
  out.normal = (m.normal * vec4<f32>(normal, 0.0)).xyz;
  out.light = normalize(global.light_position.xyz - p);
  out.view = normalize(-p);

  // O shader trabalha em espaço de câmera; portanto a distância
  // do ponto à origem é a distância do ponto à câmera.
  out.fog_distance = length(p);

  out.clip_position = global.projection * vec4<f32>(p, 1.0);
  return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
  let normal = normalize(in.normal);
  let light = normalize(in.light);
  let view = normalize(in.view);

  // SpotLight
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

  // Fog linear:
  // 1.0 perto da câmera -> mantém a cor do objeto
  // 0.0 longe da câmera -> usa a cor do fog
  let fog_factor = clamp(
    (global.fog_far - in.fog_distance) /
    (global.fog_far - global.fog_near),
    0.0,
    1.0
  );

  let final_color = mix(global.fog_color, color, fog_factor);
  return vec4<f32>(final_color, material.opacity);
}
