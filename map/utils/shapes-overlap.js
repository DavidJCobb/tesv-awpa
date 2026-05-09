
import AABB from "./aabb.js";
import Circle from "./circle.js";

export default /*bool*/ function shapes_overlap(a, b) {
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