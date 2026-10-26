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

@group(3) @binding(0) var decal_texture: texture_2d<f32>;
@group(3) @binding(1) var decal_sampler: sampler;

struct VertexOutput {
  @builtin(position) clip_position: vec4<f32>,
  @location(0) normal: vec3<f32>,
  @location(1) light: vec3<f32>,
  @location(2) view: vec3<f32>,
  @location(3) texcoord: vec2<f32>,
  @location(4) fog_distance: f32,
  @location(5) position_camera: vec3<f32>,
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
  out.fog_distance = length(p);
  out.position_camera = p;
  out.clip_position = global.projection * vec4<f32>(p, 1.0);

  let _unused_tangent = tangent;
  return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
  let clip_plane = vec4<f32>(1.0, 0.0, 0.0, 1.70);

  if (dot(vec4<f32>(in.position_camera, 1.0), clip_plane) < 0.0) {
    discard;
  }

  let normal = normalize(in.normal);
  let light = normalize(in.light);
  let view = normalize(in.view);

  let c = dot(-light, normalize(global.spot_direction));
  let cutoff = cos(global.spot_angle);

  var kspot = 0.0;
  if (c >= cutoff) {
    kspot = pow(max(c, 0.0), global.spot_exponent);
  }

  var color = material.base_color * global.light_ambient;

  let ndotl = max(dot(normal, light), 0.0);
  if (ndotl > 0.0 && kspot > 0.0) {
    color += material.base_color * global.light_diffuse * ndotl * kspot;

    let refl = normalize(reflect(-light, normal));
    let spec = pow(max(dot(refl, view), 0.0), material.shininess);

    color += material.specular_color * global.light_specular * spec * kspot;
  }

  let light2_position = vec3<f32>(-3.0, 3.0, 2.0);
  let light2_diffuse = vec3<f32>(0.30, 0.36, 0.48);
  let light2_specular = vec3<f32>(0.22, 0.26, 0.34);

  let light2 = normalize(light2_position - in.position_camera);
  let ndotl2 = max(dot(normal, light2), 0.0);

  if (ndotl2 > 0.0) {
    color += material.base_color * light2_diffuse * ndotl2;

    let refl2 = normalize(reflect(-light2, normal));
    let spec2 = pow(max(dot(refl2, view), 0.0), material.shininess);

    color += material.specular_color * light2_specular * spec2;
  }

  let decal = textureSample(decal_texture, decal_sampler, in.texcoord);
  let textured_color = color * decal.rgb;

  let fog_factor = clamp(
    (global.fog_far - in.fog_distance) /
    (global.fog_far - global.fog_near),
    0.0,
    1.0
  );

  let final_color = mix(global.fog_color, textured_color, fog_factor);

  return vec4<f32>(final_color, material.opacity * decal.a);
}
