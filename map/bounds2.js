
import get_circle_arc_by_endpoints from "./utils/get_circle_arc_by_endpoints.js";
import intersections_of_circles    from "./utils/intersections-of-circles.js";

import * as __vector_ops from "./utils/vector-ops.js";
const {distance, dot, len, midpoint, sub} = __vector_ops;

export /*bool*/ function overlaps(/*const Shape*/ a, /*const Shape*/ b) {
   if (a instanceof Circle && b instanceof AABB) {
      [a, b] = [b, a];
   }
   if (a instanceof Circle) {
      if (b instanceof Circle) {
         return distance(a.center, b.center) <= Math.max(a.radius, b.radius);
      }
   } else if (a instanceof AABB) {
      if (b instanceof AABB) {
         return (
            (a.min.x <= b.max.x && a.max.x >= b.min.x) &&
            (a.min.y <= b.max.y && a.max.y >= b.min.y) &&
            (a.min.z <= b.max.z && a.max.z >= b.min.z)
         );
      }
      if (b instanceof Circle) {
         const radius = b.radius;
         const center = b.center;
         if (distance(center, a.min) < radius)
            return true;
         if (distance(center, a.max) < radius)
            return true;
         if (distance(center, new DOMPoint(a.min.x, a.max.y)) < radius)
            return true;
         if (distance(center, new DOMPoint(a.max.x, a.min.y)) < radius)
            return true;
         
         if (center.x > a.min.x && center.x < a.max.x) {
            if (center.y > a.min.y - radius && center.y < a.max.y + radius)
               return true;
            return false;
         }
         if (center.y > a.min.y && center.y < a.max.y) {
            if (center.x > a.min.x - radius && center.x < a.max.x + radius)
               return true;
            return false;
         }
      }
   }
   return false;
}

export class AABB {
   constructor() {
      this.min = new DOMPoint(-Infinity, -Infinity, -Infinity);
      this.max = new DOMPoint( Infinity,  Infinity,  Infinity);
   }
   
   get x() { return this.min.x; }
   get y() { return this.min.y; }
   get z() { return this.min.z; }
   get width() { return this.max.x - this.min.x; }
   get height() { return this.max.y - this.min.y; }
   get depth() { return this.max.z - this.min.z; }
   
   get center() {
      return new DOMPoint(this.x + this.width / 2, this.y + this.height / 2);
   }
   
   /*bool*/ empty() /*const*/ {
      for(const axis of ["x", "y", "z"]) {
         if (this.min[axis] < this.max[axis])
            return false;
      }
      return true;
   }
   /*bool*/ equals(/*const AABB*/ other) /*const*/ {
      if (!(other instanceof AABB))
         return false;
      for(const u of ["min", "max"]) {
         const a = this[u];
         const b = other[u];
         for(const v of ["x", "y", "z"])
            if (a[v] != b[v])
               return false;
      }
      return true;
   }
   
   /*DOMRect*/ toDOMRect() /*const*/ {
      return new DOMRect(this.min.x, this.min.y, this.width, this.height);
   }
   
   /*bool*/ isOpen2D() /*const*/ {
      return !isFinite(this.width) || !isFinite(this.height);
   }
   /*bool*/ isClosed2D() /*const*/ {
      return isFinite(this.width) && isFinite(this.height);
   }
   
   /*AABB*/ clone() /*const*/ {
      let copy = new AABB();
      for(const u of ["min", "max"]) {
         const src = this[u];
         const dst = copy[u];
         for(const v of ["x", "y", "z"])
            dst[v] = src[b];
      }
      return copy;
   }
   intersect(/*const AABB*/ other) {
      if (!(other instanceof AABB))
         return;
      this.min.x = Math.max(this.min.x, other.min.x);
      this.min.y = Math.max(this.min.y, other.min.y);
      this.min.z = Math.max(this.min.z, other.min.z);
      this.max.x = Math.min(this.max.x, other.max.x);
      this.max.y = Math.min(this.max.y, other.max.y);
      this.max.z = Math.min(this.max.z, other.max.z);
   }
};

export class Circle {
   constructor(params) {
      this.center = new DOMPoint(0, 0);
      this.radius = 0;
      
      if (params) {
         this.radius   = params.radius;
         this.center.x = params.cx || params.center.x;
         this.center.y = params.cy || params.center.y;
      }
   }
   
   get cx() { return this.center.x; }
   get cy() { return this.center.y; }
   
   /*bool*/ contains(/*const Variant<Circle, DOMPoint>*/ other) /*const*/ {
      if (other instanceof Circle) {
         if (this.radius < other.radius)
            return false;
         let d = distance(this.center, other.center);
         return d <= this.radius - other.radius;
      }
      let gap = distance(other, this.center) - this.radius;
      return (gap < 0.0001);
   }
   /*bool*/ empty() /*const*/ {
      return this.radius <= 0;
   }
   /*bool*/ equals(other) /*const*/ {
      if (!(other instanceof Circle))
         return false;
      for(let k of ["radius", "cx", "cy"]) {
         let a  = this[k];
         let b  = other[k];
         let na = isNaN(a);
         let nb = isNaN(b);
         if (na != nb)
            return false;
         if (!na)
            if (a != b)
               return false;
      }
      return true;
   }
   
   /*bool*/ isOpen2D() /*const*/ {
      return isNaN(this.center.x) || isNaN(this.center.y) || isNaN(this.radius);
   }
   /*bool*/ isClosed2D() /*const*/ {
      return !this.isOpen2D();
   }
   
   /*Circle*/ clone() /*const*/ {
      let copy = new Circle();
      copy.center.x = this.center.x;
      copy.center.y = this.center.y;
      copy.radius   = this.radius;
      return copy;
   }
};

// Either a single bounding shape, or a union of multiple bounding shapes.
export class Bounds {
   constructor() {
      this.boxes   = []; // Array<AABB>
      this.circles = []; // Array<Circle>
   }
   
   /*AABB*/ coalesced_box() {
      if (!this.boxes.length)
         return null;
      if (this.boxes.length == 1) {
         return this.boxes[0].copy();
      }
      let box = new AABB();
      for(let src of this.boxes)
         box.intersect(src);
      return box;
   }
   
   /*bool*/ empty() /*const*/ {
      if (!this.boxes.length && !this.circles.length)
         return true;
      let box = this.coalesced_box();
      if (box && box.empty())
         return true;
      if (this.circles.length) {
         for(let i = 0; i < this.circles.length; ++i) {
            let c = this.circles[i];
            if (c.empty() || !c.overlaps(box))
               return true;
         }
         for(let i = 0; i + 1 < this.circles.length; ++i) {
            let c = this.circles[i];
            if (box && overlaps(v, c))
               return true;
            for(let j = i + 1; j < this.circles.length; ++j)
               if (!overlaps(c, this.circles[j]))
                  return true;
         }
      }
      return false;
   }
   
   /*Bounds*/ simplified() /*const*/ {
      let copy = new Bounds();
      {
         let box = new AABB();
         for(let src of this.boxes)
            box.intersect(src);
         copy.boxes.push(box);
      }
      copy.circles = this.circles.filter((circle) => {
         for(let other of this.circles) {
            if (other == circle)
               continue;
            if (circle.contains(other))
               return false;
         }
         return true;
      });
      if (copy.empty()) {
         copy.boxes   = [];
         copy.circles = [];
      }
      return copy;
   }
   
   render() {
      if (!this.boxes.length && !this.circles.length)
         return null;
      
      let coalesced_circles = this.circles.filter((circle) => {
         for(let other of this.circles) {
            if (other == circle)
               continue;
            if (circle.contains(other))
               return false;
         }
         return true;
      });
      
      let box = this.coalesced_box();
      if (box && !coalesced_circles.length) {
         const node = document.createElementNS("http://www.w3.org/2000/svg", "rect");
         node.style.setProperty("--x-min", box.min.x);
         node.style.setProperty("--y-min", box.min.y);
         node.style.setProperty("--x-max", box.max.x);
         node.style.setProperty("--y-max", box.max.y);
         return node;
      }
      if (coalesced_circles.length) {
         if (coalesced_circles.length == 1 && !box) {
            const src  = coalesced_circles[0];
            const node = document.createElementNS("http://www.w3.org/2000/svg", "circle");
            node.setAttribute("cx", src.cx);
            node.setAttribute("cy", src.cy);
            node.setAttribute("r",  src.radius);
            return node;
         }
         
         // Compute intersection of all circles, per:
         // https://www.benfrederickson.com/calculating-the-intersection-of-3-or-more-circles/
         
         let points = [];
         for(let i = 0; i + 1 < coalesced_circles.length; ++i) {
            let a = coalesced_circles[i];
            for(let j = i + 1; j < coalesced_circles.length; ++j) {
               let b = coalesced_circles[j];
               
               let result = intersections_of_circles(a, b);
               if (result === null)
                  return null; // no overlap
               if (result == "contains")
                  continue;
               if (result == "identical")
                  continue;
               
               let [inter_a, inter_b] = result;
               inter_a.is_intersection_of = [a, b];
               inter_b.is_intersection_of = [a, b];
               points.push(inter_a);
               points.push(inter_b);
            }
         }
         points = points.filter((p) => {
            for(let circle of coalesced_circles)
               if (!circle.contains(p))
                  return false;
            return true;
         });
         
         // We now have a polygon comprising the minimum intersection of all circles.
         
         if (points.length < 2)
            return null;
         
         const node = document.createElementNS("http://www.w3.org/2000/svg", "path");
         let   path = "";
         if (points.length == 2) {
            let a = points[0];
            let b = points[1];
            
            let circle_a = a.is_intersection_of[0];
            let circle_b = a.is_intersection_of[1];
            
            // <https://stackoverflow.com/questions/47684885/arc-svg-parameters>
            {
               let u = a;
               let v = b;
               if (circle_a.cy > circle_b.cy) {
                  a = (u.x < v.x) ? u : v;
                  b = (u.x < v.x) ? v : u;
               } else if (circle_a.cy < circle_b.cy) {
                  a = (u.x > v.x) ? u : v;
                  b = (u.x > v.x) ? v : u;
               } else {
                  a = (u.y < v.y) ? u : v;
                  b = (u.y < v.y) ? v : u;
               }
            }
            
            function _get_angle(u, v) {
               // <https://www.w3.org/TR/SVG2/implnote.html#ArcConversionEndpointToCenter>
               let sign = u.x*v.y - u.y*v.x < 0 ? -1 : 1;
               return sign * Math.acos(
                  dot(u, v)
                  /
                  (len(u) * len(v))
               );
            }
            
            // The StackOverflow source above is wrong about never needing the large-arc-flag.
            let large_a = _get_angle(sub(a, circle_a.center), sub(b, circle_a.center)) % (2 * Math.PI);
            if (large_a > 0)
               large_a += 2 * Math.PI;
            large_a = (large_a < Math.PI);
            let large_b = _get_angle(sub(a, circle_b.center), sub(b, circle_b.center)) % (2 * Math.PI);
            if (large_b > 0)
               large_b += 2 * Math.PI;
            large_b = (large_b > Math.PI);
            
            path = `
               M${a.x},${a.y}
               A${circle_a.radius} ${circle_a.radius} 0 ${large_a?'1':'0'} 1 ${b.x},${b.y}
               A${circle_b.radius} ${circle_b.radius} 0 ${large_b?'1':'0'} 1 ${a.x},${a.y}
               Z
            `;
         } else {
            // Sort the points so they're all (counter?)clockwise.
            {
               let center = new DOMPoint(0, 0);
               for(let point of points) {
                  center.x += point.x;
                  center.y += point.y;
               }
               center.x /= points.length;
               center.y /= points.length;
               
               for(let point of points)
                  point.angle = Math.atan2(point.x - center.x, point.y - center.y);
               points.sort((a, b) => { return b.angle - a.angle });
            }
            
            path = `M${points[0].x},${points[0].y} `;
            for(let i = 1; i <= points.length; ++i) {
               let a = points[i - 1];
               let b = points[i % points.length];
               
               let mid = midpoint(a, b);
               let arc = null;
               for(let j = 0; j < 2; ++j) {
                  const circle = a.is_intersection_of[j];
                  if (b.is_intersection_of.indexOf(circle) <= -1)
                     continue;
                  let current_arc = get_circle_arc_by_endpoints(circle, a, b);
                  if (arc === null || arc.sagitta > current_arc.sagitta) {
                     arc = current_arc;
                  }
               }
               if (arc) {
                  path += `A${arc.circle.radius} ${arc.circle.radius} 0 0 1 ${b.x} ${b.y} `;
               } else {
                  path += `L${b.x},${b.y} `;
               }
            }
         }
         path += 'Z';
         node.setAttribute("d", path);
         return node;
      }
      return null;
   }
};