
function distance(a, b) {
   return Math.sqrt((b.x-a.x)**2 + (b.y-a.y)**2);
}
function midpoint(a, b) {
   return new DOMPoint((a.x + b.x) / 2, (a.y + b.y) / 2, (a.z + b.z) / 2);
}

const CIRCLE_RADIANS = 2 * Math.PI;

function clamp_radians(r) {
   r %= CIRCLE_RADIANS;
   if (r < 0)
      r += CIRCLE_RADIANS;
   return r;
}

export default function get_circle_arc_by_endpoints(circle, a, b) {
   let angle_1    = Math.atan2(a.x - circle.cx, a.y - circle.cy);
   let angle_2    = Math.atan2(b.x - circle.cx, b.y - circle.cy);
   let angle_diff = clamp_radians(angle_2 - angle_1);
   
   let arc_angle   = angle_2 - (angle_diff / 2);
   let arc_sagitta = distance(
      midpoint(a, b),
      new DOMPoint(
         circle.cx + circle.radius * Math.sin(arc_angle),
         circle.cy + circle.radius * Math.cos(arc_angle)
      )
   );
   return {
      circle:    circle,
      endpoints: [a, b],
      angle:     angle_diff,
      length:    circle.radius * angle_diff,
      sagitta:   arc_sagitta,
   };
}