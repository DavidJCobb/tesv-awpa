
function dot(a, b) {
   return a.x*b.x + a.y*b.y;
}
function len(v) {
   return Math.sqrt(v.x**2 + v.y**2);
}

export default class Arc {
   constructor(circle, endpoint_a, endpoint_b, sweep) {
      this.circle = circle;
      this.points = [endpoint_a, endpoint_b];
      this.sweep  = !!sweep;
      
      let rx = this.radius;
      let ry = this.radius;
      
      // <https://w3c.github.io/svgwg/svg2-draft/implnote.html#ArcConversionEndpointToCenter>
      
      let midpoint = new DOMPoint(
         this.points[1].x - this.points[0].x,
         this.points[1].y - this.points[0].y
      );
      this.midpoint = midpoint;
      
      let shifted_center = new DOMPoint(
         this.circle.center.x - midpoint.x,
         this.circle.center.y - midpoint.y
      );
      
      function _get_angle(u, v) {
         let sign = u.x*v.y - u.y*v.x < 0 ? -1 : 1;
         return sign * Math.acos(
            dot(u, v)
            /
            (len(u) * len(v))
         );
      }
      
      /*//
      let angle_delta = _get_angle(
         new DOMPoint(
            ((this.points[0].x - midpoint.x) - shifted_center.x) / rx,
            ((this.points[0].y - midpoint.y) - shifted_center.y) / ry
         ),
         new DOMPoint(
            ((-this.points[0].x - midpoint.x) - shifted_center.x) / rx,
            ((-this.points[0].y - midpoint.y) - shifted_center.y) / ry
         )
      ) % (2 * Math.PI);
      //*/
let angle_delta = _get_angle(
   new DOMPoint(
      (this.points[0].x - this.circle.cx) / rx,
      (this.points[0].y - this.circle.cy) / ry
   ),
   new DOMPoint(
      (this.points[1].x - this.circle.cx) / rx,
      (this.points[1].y - this.circle.cy) / ry
   )
) % (2 * Math.PI);
      if (!this.sweep) {
         if (angle_delta > 0)
            angle_delta -= (2 * Math.PI);
      } else {
         if (angle_delta < 0)
            angle_delta += (2 * Math.PI);
      }
      this.angle = angle_delta;
      
      /*//
      if (angle_delta <= 0)
         this.sweep = false;
      else if (angle_delta > 0)
         this.sweep = true;
      //*/
      
      //if (Math.abs(angle_delta) > Math.PI)
      //   this.large_arc = true;
      //else
         this.large_arc = false;
   }
   
   get radius() { return this.circle.radius; }
   
   toString() {
      return `A${this.radius} ${this.radius} 0 ${this.large_arc ? '1' : '0'} ${this.sweep ? '1' : '0'} ${this.points[1].x} ${this.points[1].y}`;
   }
};