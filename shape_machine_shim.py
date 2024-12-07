from numpy import ndarray
from typing import Any, List

class Engine:
    current_design: Any
    to_design: Any

class CommunicationLayer:
    def replace_current_design(self, current_design: Any, to_design: Any):
        pass

engine: Engine

communication_layer: CommunicationLayer

class ElementAttributes:
    def __init__(self, name: str):
        pass

def make_attributes(*args, **kwargs) -> ElementAttributes:
    pass

class Arc:
    def __init__(self, center: ndarray[3], start: ndarray[3], midpoint: ndarray[3], end: ndarray[3], attributes: ElementAttributes):
        pass

class Circle(Arc):
    def __init__(self, center: ndarray[3], radius: float, attributes: ElementAttributes):
        super().__init__(center, center, center, center, attributes)



class Line:
    def __init__(self, start: ndarray[3], end: ndarray[3], attributes: ElementAttributes, rectify_endpoints: bool = True):
        pass

class Point:
    location: ndarray[3]
    def __init__(self, location: ndarray[3], attributes: ElementAttributes):
        pass

class Shape:
    def __init__(self, lines: List[Line], arcs: List[Arc], points: List[Point], maximal: bool = False):
        pass