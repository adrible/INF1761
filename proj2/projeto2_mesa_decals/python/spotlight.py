from __future__ import annotations

import math
from typing import Any

import graphics_math as gm
from light import Light


class SpotLight(Light):
    """Luz spot definida por posição, direção, abertura e expoente."""

    def __init__(
        self,
        x: float,
        y: float,
        z: float,
        dx: float,
        dy: float,
        dz: float,
        angle: float,
        exponent: float,
        space: str = "world",
        **values: Any,
    ) -> None:
        super().__init__(space, **values)
        self.set_position(x, y, z)
        self.set_direction(dx, dy, dz)
        self.set_angle(angle)
        self.set_exponent(exponent)

    def set_position(self, x: float, y: float, z: float) -> None:
        self.set("light_position", gm.vec4(x, y, z, 1.0))

    def set_direction(self, x: float, y: float, z: float) -> None:
        self.set("spot_direction", gm.vec3(x, y, z))

    def set_angle(self, angle: float) -> None:
        """Ângulo de abertura em graus; o shader recebe em radianos."""
        self.set("spot_angle", math.radians(angle))

    def set_exponent(self, exponent: float) -> None:
        self.set("spot_exponent", float(exponent))

    def map(self, matrix: gm.Mat4) -> dict[str, Any]:
        # Posição: w=1, portanto sofre translação.
        position = matrix @ self.get("light_position")

        # Direção: w=0, portanto ignora translação e é normalizada.
        d = self.get("spot_direction")
        direction = (matrix @ gm.vec4(d[0], d[1], d[2], 0.0))[:3]
        direction = gm.normalize(direction)

        return {
            "light_position": position,
            "spot_direction": direction,
        }
