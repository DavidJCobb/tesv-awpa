
const CIRCLE_RADIANS = 2 * Math.PI;

export function clamp_radians(r) {
   r %= CIRCLE_RADIANS;
   if (r < 0)
      r += CIRCLE_RADIANS;
   return r;
}
