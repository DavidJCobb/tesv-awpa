
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