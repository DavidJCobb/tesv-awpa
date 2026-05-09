
export function add_in_place(a, v) {
   if (v.x || v.x === 0) {
      a.x += v.x;
      a.y += v.y;
      return;
   }
   a.x += v;
   a.y += v;
}
export function div_in_place(a, v) {
   a.x /= v;
   a.y /= v;
}

export function distance(a, b) {
   return Math.sqrt((b.x-a.x)**2 + (b.y-a.y)**2);
}
export function dot(a, b) {
   return a.x*b.x + a.y*b.y;
}
export function len(v) {
   return Math.sqrt(v.x**2 + v.y**2);
}
export function midpoint(a, b) {
   return new DOMPoint((a.x + b.x) / 2, (a.y + b.y) / 2, (a.z + b.z) / 2);
}
export function sub(a, b) {
   return new DOMPoint(a.x-b.x, a.y-b.y);
}

// <https://www.w3.org/TR/SVG2/implnote.html#ArcConversionEndpointToCenter>
export function angle_between(u, v) {
   let sign = u.x*v.y - u.y*v.x < 0 ? -1 : 1;
   return sign * Math.acos(
      dot(u, v)
      /
      (len(u) * len(v))
   ) % (2 * Math.PI);
}