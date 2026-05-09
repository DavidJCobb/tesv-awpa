
// <https://stackoverflow.com/a/3349134>
// Per <https://paulbourke.net/geometry/circlesphere/>.
export default function intersections_of_circles(a, b) {
   const dx = b.center.x - a.center.x;
   const dy = b.center.y - a.center.y;
   const d  = Math.sqrt(dx**2 + dy**2);
   if (d > a.radius + b.radius)
      return null; // no overlap
   if (d < Math.abs(a.radius - b.radius))
      return "contains"; // one circle is contained within the other
   if (d == 0 && a.radius == b.radius)
      return "identical"; // circles are identical
   
   //
   // Let's define some terms:
   //
   //  - The "mainline" is the infinitely long line passing through both of 
   //    the circles' centerpoints.
   //
   //  - The "crossline" is the infinitely long line passing through both of 
   //    the points of intersection between the circles. The crossline is 
   //    perpendicular to the mainline.
   //
   //  - The "nexus" is the point at which the mainline and crossline meet.
   //
   
   const nexus_distance_to_a   = (a.radius**2 - b.radius**2 + d**2) / (2 * d);
   const nexus_distance_to_poi = Math.sqrt(a.radius**2 - nexus_distance_to_a**2);
   
   const nexus_x = a.center.x + nexus_distance_to_a*dx/d;
   const nexus_y = a.center.y + nexus_distance_to_a*dy/d;
   
   //
   // Each point of intersection is the same offset away from the nexus, but 
   // in opposite directions.
   //
   const intersection_offset_x_from_nexus = nexus_distance_to_poi*dy/d;
   const intersection_offset_y_from_nexus = nexus_distance_to_poi*dx/d;
   return [
      new DOMPoint(
         nexus_x + intersection_offset_x_from_nexus,
         nexus_y - intersection_offset_y_from_nexus
      ),
      new DOMPoint(
         nexus_x - intersection_offset_x_from_nexus,
         nexus_y + intersection_offset_y_from_nexus
      )
   ];
}
