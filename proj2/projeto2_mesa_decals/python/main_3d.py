from pathlib import Path
from typing import Any

import wgpu
from rendercanvas.glfw import RenderCanvas, loop

from camera3d import Camera3D
from spotlight import SpotLight
from shader import Shader
from pipeline import Pipeline
from phongmaterial import PhongMaterial
from transform import Transform
from node import Node
from scene import Scene
from renderer import Renderer
from cube import Cube
from sphere import Sphere
from texture import Texture
from sampler import Sampler
from textureset import TextureSet


canvas = None
device = None
context = None
renderer = None
camera = None
scene = None

BASE_DIR = Path(__file__).resolve().parent.parent
SPOT_SHADER = BASE_DIR / "shaders" / "ilum_frag" / "spot.wgsl"
SPOT_TEXTURED_SHADER = BASE_DIR / "shaders" / "ilum_frag" / "spot_textured.wgsl"
TEXTURE_DIR = BASE_DIR / "textures"


def transform(x, y, z, sx, sy, sz):
    t = Transform()
    t.translate(x, y, z)
    t.scale(sx, sy, sz)
    return t


def initialize(device, target_format):
    global camera, scene

    # ---------------------------------------------------------
    # Câmera + arcball
    # ---------------------------------------------------------
    camera = Camera3D(5.0, 4.5, 6.0)
    camera.set_center(0.0, 1.5, 0.0)

    arcball = camera.create_arcball()
    arcball.attach(canvas)

    # ---------------------------------------------------------
    # SpotLight (mantida da Tarefa 2.2)
    # ---------------------------------------------------------
    light = SpotLight(
        2.5, 5.5, 3.0,
        -2.5, -3.4, -3.0,
        28.0,
        12.0,
        space="world",
    )
    light.set_ambient(0.04, 0.04, 0.04)
    light.set_diffuse(1.0, 1.0, 1.0)
    light.set_specular(1.0, 1.0, 1.0)

    # ---------------------------------------------------------
    # Materiais
    # ---------------------------------------------------------
    branco = PhongMaterial(0.85, 0.85, 0.85)
    vermelho = PhongMaterial(1.00, 0.25, 0.25)

    # Para os objetos texturizados, a textura fornece a padronagem de cor.
    bloco_material = PhongMaterial(1.0, 1.0, 1.0)
    esfera_material = PhongMaterial(1.0, 1.0, 1.0)

    # ---------------------------------------------------------
    # Formas
    # ---------------------------------------------------------
    cube = Cube(device)
    sphere = Sphere(device, 32, 32)

    # ---------------------------------------------------------
    # Pipeline normal: SpotLight sem textura
    # ---------------------------------------------------------
    shader = Shader(
        device,
        str(SPOT_SHADER),
        light=light,
        space="camera",
    )

    shader.set_vertex_buffers([
        {
            "array_stride": 3 * 4,
            "step_mode": "vertex",
            "attributes": [
                {"format": "float32x3", "offset": 0, "var_name": "coord"}
            ],
        },
        {
            "array_stride": 3 * 4,
            "step_mode": "vertex",
            "attributes": [
                {"format": "float32x3", "offset": 0, "var_name": "normal"}
            ],
        },
    ])

    pipeline = Pipeline(
        shader,
        target_format,
        primitive={"cull_mode": "back"},
    )

    shader.add_material(branco)
    shader.add_material(vermelho)

    # ---------------------------------------------------------
    # Pipeline texturizado: mesma SpotLight + decal
    # ---------------------------------------------------------
    textured_shader = Shader(
        device,
        str(SPOT_TEXTURED_SHADER),
        light=light,
        space="camera",
    )

    # Cube e Sphere do código-base disponibilizam:
    # slot 0 = coord, 1 = normal, 2 = tangent, 3 = texcoord.
    textured_shader.set_vertex_buffers([
        {
            "array_stride": 3 * 4,
            "step_mode": "vertex",
            "attributes": [
                {"format": "float32x3", "offset": 0, "var_name": "coord"}
            ],
        },
        {
            "array_stride": 3 * 4,
            "step_mode": "vertex",
            "attributes": [
                {"format": "float32x3", "offset": 0, "var_name": "normal"}
            ],
        },
        {
            "array_stride": 3 * 4,
            "step_mode": "vertex",
            "attributes": [
                {"format": "float32x3", "offset": 0, "var_name": "tangent"}
            ],
        },
        {
            "array_stride": 2 * 4,
            "step_mode": "vertex",
            "attributes": [
                {"format": "float32x2", "offset": 0, "var_name": "texcoord"}
            ],
        },
    ])

    textured_pipeline = Pipeline(
        textured_shader,
        target_format,
        primitive={"cull_mode": "back"},
    )

    textured_shader.add_material(bloco_material)
    textured_shader.add_material(esfera_material)

    # ---------------------------------------------------------
    # Decals / texturas de padronagem de cor
    # ---------------------------------------------------------
    sampler = Sampler(
        device,
        "decal_sampler",
        address_mode_u="repeat",
        address_mode_v="repeat",
        mag_filter="linear",
        min_filter="linear",
    )

    bloco_texture = Texture(
        device,
        "decal_texture",
        str(TEXTURE_DIR / "bloco_xadrez.png"),
    )
    bloco_decal = TextureSet([bloco_texture, sampler])
    textured_shader.add_texture_set(bloco_decal)

    esfera_texture = Texture(
        device,
        "decal_texture",
        str(TEXTURE_DIR / "esfera_listras.png"),
    )
    esfera_decal = TextureSet([esfera_texture, sampler])
    textured_shader.add_texture_set(esfera_decal)

    # ---------------------------------------------------------
    # Mesa
    # ---------------------------------------------------------
    tampo = Node(
        trf=transform(0.0, 2.20, 0.0, 4.0, 0.25, 3.0),
        apps=[branco],
        shps=[cube],
    )

    perna1 = Node(
        trf=transform(-1.75, 0.0, -1.25, 0.25, 2.20, 0.25),
        apps=[branco],
        shps=[cube],
    )
    perna2 = Node(
        trf=transform(1.75, 0.0, -1.25, 0.25, 2.20, 0.25),
        apps=[branco],
        shps=[cube],
    )
    perna3 = Node(
        trf=transform(-1.75, 0.0, 1.25, 0.25, 2.20, 0.25),
        apps=[branco],
        shps=[cube],
    )
    perna4 = Node(
        trf=transform(1.75, 0.0, 1.25, 0.25, 2.20, 0.25),
        apps=[branco],
        shps=[cube],
    )

    mesa = Node(nodes=[tampo, perna1, perna2, perna3, perna4])

    # ---------------------------------------------------------
    # Objetos sobre a mesa
    # ---------------------------------------------------------

    # 1º objeto com decal: bloco
    bloco = Node(
        pipeline=textured_pipeline,
        trf=transform(-0.55, 2.45, 0.20, 1.40, 0.50, 1.00),
        apps=[bloco_material, bloco_decal],
        shps=[cube],
    )

    # 2º objeto com decal: esfera verde/listrada
    esfera_texturizada = Node(
        pipeline=textured_pipeline,
        trf=transform(-0.55, 3.33, 0.20, 0.38, 0.38, 0.38),
        apps=[esfera_material, esfera_decal],
        shps=[sphere],
    )

    # Esfera vermelha permanece sem textura para dar contraste
    esfera_vermelha = Node(
        trf=transform(0.90, 2.97, -0.50, 0.52, 0.52, 0.52),
        apps=[vermelho],
        shps=[sphere],
    )

    root = Node(
        pipeline=pipeline,
        nodes=[mesa, bloco, esfera_texturizada, esfera_vermelha],
    )

    scene = Scene(root)


def draw():
    target_texture = context.get_current_texture()
    renderer.render(target_texture, scene, camera)


def on_key(event: Any):
    if event["key"] == "q":
        canvas.close()


def main():
    global canvas, device, context, renderer

    canvas = RenderCanvas(
        size=(640, 480),
        title="Projeto 2 - Mesa com SpotLight e Decals",
        update_mode="continuous",
        max_fps=60,
    )

    adapter = wgpu.gpu.request_adapter_sync()
    device = adapter.request_device_sync()

    context = canvas.get_context("wgpu")
    target_format = context.get_preferred_format(device.adapter)
    context.configure(device=device, format=target_format)

    renderer = Renderer(
        device,
        depth_test=True,
        clear_value=(0.12, 0.12, 0.14, 1.0),
    )

    initialize(device, target_format)

    canvas.add_event_handler(on_key, "key_down")
    canvas.request_draw(draw)
    loop.run()


if __name__ == "__main__":
    main()
