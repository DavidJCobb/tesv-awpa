
import get_circle_arc_by_endpoints from "./utils/get_circle_arc_by_endpoints.js";
import intersections_of_circles    from "./utils/intersections-of-circles.js";

import { clamp_radians } from "./utils/angle-ops.js";
import { add_in_place, angle_between, distance, div_in_place, dot, len, midpoint, sub } from "./utils/vector-ops.js";

import AABB from "./utils/aabb.js";
import Circle from "./utils/circle.js";
export { AABB, Circle };

import overlaps from "./utils/shapes-overlap.js";

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
      copy.circles = Circle.filter_wholly_enveloped_circles(this.circles);
      if (copy.empty()) {
         copy.boxes   = [];
         copy.circles = [];
      }
      return copy;
   }
   
   render() {
      if (!this.boxes.length && !this.circles.length)
         return null;
      
      const coalesced_circles = Circle.filter_wholly_enveloped_circles(this.circles);
      
      let box = this.coalesced_box();
      if (box && !coalesced_circles.length) {
         return box.render();
      }
      if (coalesced_circles.length) {
         if (coalesced_circles.length == 1 && !box) {
            return coalesced_circles[0].render();
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
            
            // The StackOverflow source above is wrong about never needing the large-arc-flag.
            // Strangely, though, these calculations here are what you'd do to get the sweep 
            // flag, but we have to pass it as the large-angle flag for it to work.
            let large_a = angle_between(sub(a, circle_a.center), sub(b, circle_a.center));
            large_a = (large_a < 0);
            let large_b = angle_between(sub(a, circle_b.center), sub(b, circle_b.center));
            large_b = (large_b > 0);
            
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
                  add_in_place(center, point);
               }
               div_in_place(center, points.length);
               
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
         
         // TODO: box/circle intersections not yet implemented
      }
      return null;
   }
};