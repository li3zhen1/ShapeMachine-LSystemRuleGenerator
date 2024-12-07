from enum import Enum
from typing import List, Tuple, Optional, Any
from dataclasses import dataclass
import numpy as np


try:
    from shapemachine.geometry.shape import Shape
    from shapemachine.geometry.arc import Arc, Circle
    from shapemachine.geometry.point import Point
    from shapemachine.geometry.line import Line
except ImportError:
    # This is a hack to make the auto-completion work in VS Code
    from shape_machine_shim import *


next_color_attribute = {
    "Black": "Blue",
    "Blue": "Orange",
    "Orange": "Pink",
    "Pink": "Green",
    "Green": "Red",
    "Red": "Black"
}

class ColorAttribute(str, Enum):
    Black = "Black"
    Blue = "Blue"
    Orange = "Orange"
    Pink = "Pink"
    Green = "Green"
    Red = "Red"

    def make_attributes(self, thick: bool = False, *additional) -> Any:
        if thick:
            return make_attributes(f"{self.value} Thick", *additional)
        return make_attributes(self.value, *additional)

    def next(self):
        return ColorAttribute(next_color_attribute[self.value])




@dataclass
class ShapeMachineTemplateMatch:
    lhs_point: Point
    rhs_point: Point

    @staticmethod
    def extract_from_current_design() -> List['ShapeMachineTemplateMatch']:
        points = engine.current_design.points
        matches = { }
        for point in points:
            if point.attributes[2] == 'Shape Machine::template':
                k = point.location[1]
                target_key: Optional[float] = None
                for key in matches:
                    if abs(key - k) < 1e-3:
                        target_key = key
                        break
                if target_key is None:
                    matches[k] = { 'lhs': point, 'rhs': None }
                else:
                    existing_point = matches[target_key]['lhs']
                    if existing_point[0] > point[0]:
                        matches[target_key]['lhs'] = point
                        matches[target_key]['rhs'] = existing_point
                    else:
                        matches[target_key]['rhs'] = point

        unsorted = [ShapeMachineTemplateMatch(match['lhs'], match['rhs']) for match in \
               filter(lambda x: x['rhs'] is not None, matches.values())]
        return sorted(unsorted, key=lambda x: -x.lhs_point.location[1])





@dataclass
class LineDescriptor:
    start: np.array
    end: np.array
    attr: ColorAttribute
    is_thick: bool

    def make_attributes(self, *args) -> Any:
        return self.attr.make_attributes(self.is_thick, *args)

    def make_line(self, *args) -> Line:
        return Line(self.start, self.end, self.make_attributes(*args))

    def scaled(self, a: float, b: float) -> "LineDescriptor":
        return LineDescriptor(a * self.start + b, a * self.end + b, self.attr, self.is_thick)

@dataclass
class PointDescriptor:
    location: np.array
    attr: ColorAttribute
    is_thick: bool

    def make_attributes(self) -> Any:
        return self.attr.make_attributes(thick=self.is_thick)


    def make_point(self) -> Point:
        return Point(self.location, self.make_attributes())

    def scaled(self, a: float, b: float) -> "PointDescriptor":
        return PointDescriptor(a * self.location + b, self.attr, self.is_thick)


@dataclass
class EnvironmentValues:
    angle: float
    initial_angle: float = 0.0
    line_length: float = 10.0
    line_length_factor: float = 1.0
    forward_chars: str = "F"



    draw_point_on_terminal: bool = False
    draw_point_for_direction: bool = True
    draw_point_only_on_last_line_segment: bool = False


    @property
    def color_dict(self):
        return {
            char: ColorAttribute(color) for char, color in zip(self.forward_chars, ["Blue", "Orange", "Pink", "Green", "Red"])
        }


@dataclass
class Rule:
    lhs: str
    rhs: str


@dataclass
class LSystem:
    rules: List[Rule]
    axiom: str

    env: EnvironmentValues

    def generate_draw_scripts_on_template(self, matches: list[ShapeMachineTemplateMatch]):
        if len(matches) < len(self.rules):
            raise ValueError("The number of matches and rules do not match")
        lines = []
        points = []
        for i in range(len(self.rules)):
            print(f"[DEBUG] 1@{i}")
            l, p = self._generate_draw_scripts_on_template(self.rules[i], i, matches[i])
            lines+=l
            points+=p
        engine.current_design += Shape(lines, [], points)
        communication_layer.replace_current_design(engine.current_design, engine.to_design)


    def _generate_draw_scripts_on_template(self, rule: Rule, nth_application: int, template: ShapeMachineTemplateMatch):
        print(f"[DEBUG] _generate_draw_scripts_on_template")
        ld, pd, start, end = self._get_shape_descriptors(rule.rhs, [0,0,0])

        lowest_y= min([l.start[1] for l in ld] + [l.end[1] for l in ld] + [p.location[1] for p in pd])
        print(f"lowest_y  {lowest_y}")

        concrete_lines = []
        concrete_points = []

        y_compensation = template.rhs_point.location[1] - lowest_y + 10.0

        ld = [LineDescriptor(l.start + np.array([0, y_compensation, 0]), l.end + np.array([0, y_compensation, 0]), l.attr, l.is_thick) for l in ld]
        pd = [PointDescriptor(p.location + np.array([0, y_compensation, 0]), p.attr, p.is_thick) for p in pd]
        start = start + np.array([0, y_compensation, 0])
        end = end + np.array([0, y_compensation, 0])

        middle_x = (start[0] + end[0]) / 2
        x_compensation = template.rhs_point.location[0] - middle_x

        ld = [LineDescriptor(l.start + np.array([x_compensation, 0, 0]), l.end + np.array([x_compensation, 0, 0]), l.attr, l.is_thick) for l in ld]
        pd = [PointDescriptor(p.location + np.array([x_compensation, 0, 0]), p.attr, p.is_thick) for p in pd]
        start = start + np.array([x_compensation, 0, 0])
        end = end + np.array([x_compensation, 0, 0])

        print(f"Compensated rhs start: {start}, end: {end}")


        lhs_x_compensation = template.lhs_point.location[0] - middle_x - x_compensation

        start = start + np.array([lhs_x_compensation, 0, 0])
        end = end + np.array([lhs_x_compensation, 0, 0])

        print(f"Compensated lhs start: {start}, end: {end}")



        start_point = start

        #angle from start to end
        current_angle = np.arctan2(end[1] - start[1], end[0] - start[0])

        current_attr_name = ColorAttribute(self.env.color_dict[rule.lhs[0]])

        direction_indicator_angle = np.pi / 7

        def make_directed_line(current_angle, length):
            nonlocal start_point
            nonlocal current_attr_name

            end_point = start_point + np.array([np.cos(current_angle), np.sin(current_angle), 0]) * length

            print(f"@@@ start: {start_point}, end: {end_point}")

            ld.append(
                LineDescriptor(start_point, end_point, ColorAttribute(current_attr_name), False)
            )
            p_pos = end_point + np.array(
                [-np.sin(current_angle + direction_indicator_angle),
                 np.cos(current_angle + direction_indicator_angle), 0]) * length / 5
            pd.append(
                PointDescriptor(p_pos, ColorAttribute(current_attr_name), False)
            )
            pd.append(
                PointDescriptor(end_point, ColorAttribute("Black"), True)
            )

            start_point = end_point

        make_directed_line(current_angle, np.linalg.norm(end - start))

        for l in ld:
            concrete_lines.append(l.make_line())
        for p in pd:
            concrete_points.append(p.make_point())

        return concrete_lines, concrete_points


    def generate_axiom(self):
        ld, pd, start, end = self._get_shape_descriptors(self.axiom, [0,0,0], True)
        lines = []
        points = []
        for l in ld:
            lines.append(l.make_line())
        for p in pd:
            points.append(p.make_point())
        engine.current_design += Shape(lines, [], points)
        communication_layer.replace_current_design(engine.current_design, engine.to_design)


    def _get_shape_descriptors(self, seq: str, zero_coord: np.array, activate = False) -> Tuple[
        List[LineDescriptor],
        List[PointDescriptor],
        np.array, # start
        np.array, # end
    ]:
        print(f"[DEBUG] _get_shape_descriptors")
        lines: List[LineDescriptor] = []
        points: List[PointDescriptor] = []

        current_angle: float = self.env.initial_angle
        current_attr_name = ColorAttribute(self.env.color_dict[self.env.forward_chars[0]])
        start_point = zero_coord

        position_stack = []

        angle_stack = []

        _recorded_start_point = start_point

        direction_indicator_angle = np.pi / 7  # choose a bad degree to avoid overlapping with lines

        def make_directed_line(angle, activate_line, length=self.env.line_length):
            nonlocal start_point
            nonlocal current_angle
            nonlocal current_attr_name


            end_point = start_point + np.array([np.cos(current_angle), np.sin(current_angle), 0]) * length

            print(f"start: {start_point}, end: {end_point}")

            lines.append(
                LineDescriptor(start_point, end_point, ColorAttribute(current_attr_name), False)
            )
            print(f"[DEBUG] LineDescriptor appended")
            p_pos = end_point + np.array(
                [-np.sin(current_angle + direction_indicator_angle),
                 np.cos(current_angle + direction_indicator_angle), 0]) * length / 5
            points.append(
                PointDescriptor(p_pos, ColorAttribute(current_attr_name), False)
            )

            print(f"[DEBUG] PointDescriptor appended")

            points.append(
                PointDescriptor(end_point, ColorAttribute.Black, activate_line)
            )

            print(f"[DEBUG] terminal PointDescriptor appended")
            start_point = end_point

        i = 0
        for char in seq:
            print(f"[DEBUG] for char in seq: {char}")
            if char in self.env.forward_chars:
                current_attr_name = ColorAttribute(self.env.color_dict[char])  # "Orange" if current_attr_name == "Black" else "Black"
                i += 1
                make_directed_line(current_angle, activate)
            elif char == "+":
                current_angle += self.env.angle
            elif char == "-":
                current_angle -= self.env.angle
            elif char == "[":
                position_stack.append(start_point)
                angle_stack.append(current_angle)
            elif char == "]":
                start_point = position_stack.pop(-1)
                current_angle = angle_stack.pop(-1)
            else:
                point_pos = start_point
                points.append(
                    PointDescriptor(point_pos, ColorAttribute(self.env.color_dict[char]), True)
                )

        return lines, points, _recorded_start_point, start_point


sys = LSystem(
    [
        Rule(lhs="A", rhs="A-B--B+A++AA+B-"),
        Rule(lhs="B", rhs="+A-BB--B-A++A+B"),
    ],
    "A",
    EnvironmentValues(
        np.pi / 3,
        forward_chars="AB",
    )
)

sm_templates = ShapeMachineTemplateMatch.extract_from_current_design()

sys.generate_draw_scripts_on_template(sm_templates)