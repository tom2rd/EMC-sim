"""
Created on Mon Apr 19 21:25:52 2021
@author: 394493: Alexander Kohlgraf

- Loads .obj and outputs Nec wire code, where edges are represented by wires.
- Output is automatically put into the clipboard, to simply CTRL + V it into a NEC file.
- Supports Faces and Lines (only an edge, not a face).
- Supports only one Object within the .obj file.
- If necpp is true, then nec2++ format will be used instead.
- Start tag is the tag of the first wire, counting up.
- All wires will be cut up into segments of roughly the set segment length.
- While using a radius as a number is possible, it is more practical to use a string,
  which is substituted by the nec engine of choice.
"""

import pandas as pd
import numpy as np

class Nec:
    def __init__(self, path: str, start_tag: int = 1, segment_length: float = 0.02, necpp: bool = False, radius: str = "r"):
        self.path = path
        self.start_tag = start_tag - 1
        self.segment_length = segment_length
        self.necpp = necpp
        self.radius = radius
        self.object_name = []
        self.object_vertices = []
        self.object_face_vertices = []
        self.object_line_vertices = []

        # Read list of vertices
        with open(path, "r") as f:
            lines = f.readlines()

        for line in lines:
            if line.startswith("o "):
                self.object_name.append(line[2:].strip())
            elif line.startswith("v "):
                vertex = [float(i) for i in line[2:].split()]
                self.object_vertices.append(vertex)
            elif line.startswith("f "):
                face = [int(i.split("/")[0]) for i in line[2:].split()]
                self.object_face_vertices.append(face)
            elif line.startswith("l "):
                line_vertex = [int(i) for i in line[2:].split()]
                self.object_line_vertices.append(line_vertex)

        self.edges = self.edge_list()
        if necpp:
            self.write_necpp()
        else:
            self.write_nec()

    def edge_list(self):
        edges = []
        for face in self.object_face_vertices:
            for i in range(len(face)):
                edge = (face[i], face[(i + 1) % len(face)])
                if edge not in edges and (edge[1], edge[0]) not in edges:
                    edges.append(edge)
        for line in self.object_line_vertices:
            for i in range(len(line) - 1):
                edge = (line[i], line[i + 1])
                if edge not in edges and (edge[1], edge[0]) not in edges:
                    edges.append(edge)
        return edges

    def write_nec(self):
        final = ""
        for i, edge in enumerate(self.edges):
            vert_1 = self.object_vertices[edge[0] - 1]
            vert_2 = self.object_vertices[edge[1] - 1]
            x1, y1, z1 = vert_1
            x2, y2, z2 = vert_2
            segments = max(1, np.ceil(np.sqrt((x1 - x2) ** 2 + (y1 - y2) ** 2 + (z1 - z2) ** 2) / self.segment_length))
            final += f"GW\t{self.start_tag + i}\t{segments}\t{x1}\t{y1}\t{z1}\t{x2}\t{y2}\t{z2}\t{self.radius}\n"
        
        print("Open Nec Editor after Entering this, otherwise weird bug where calc won't start")
        df = pd.DataFrame([final])
        df.to_clipboard(index=False, header=False)
        print("hello")

    def write_necpp(self):
        # Similar to write_nec, but formatted for nec2++ usage.
        pass

# Usage example:
# nec = Nec(path="your_path_to_obj_file.obj", start_tag=1, segment_length=0.02, necpp=False, radius="r")
