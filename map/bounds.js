export class Bounds {
   constructor() {
      this.min = new DOMPoint(-Infinity, -Infinity, -Infinity);
      this.max = new DOMPoint( Infinity,  Infinity,  Infinity);
   }
   
   toRect() {
      return new DOMRect(this.min.x, this.min.y, this.max.x - this.min.x, this.max.y - this.min.y);
   }
   
   isOpen2D() {
      return (
         this.min.x == -Infinity || this.min.y == -Infinity
      || this.max.x ==  Infinity || this.max.y ==  Infinity
      );
   }
   isClosed2D() {
      return !this.isOpen2D();
   }
   
   clone() {
      let copy = new Bounds();
      copy.min.x = this.min.x;
      copy.min.y = this.min.y;
      copy.min.z = this.min.z;
      copy.max.x = this.max.x;
      copy.max.y = this.max.y;
      copy.max.z = this.max.z;
      return copy;
   }
   intersect(other) {
      if (other instanceof BoundingCircle)
         return;
      this.min.x = Math.max(this.min.x, other.min.x);
      this.min.y = Math.max(this.min.y, other.min.y);
      this.min.z = Math.max(this.min.z, other.min.z);
      this.max.x = Math.min(this.max.x, other.max.x);
      this.max.y = Math.min(this.max.y, other.max.y);
      this.max.z = Math.min(this.max.z, other.max.z);
   }
};

export class BoundingCircle {
   constructor() {
      this.center = new DOMPoint(NaN, NaN);
      this.radius = NaN;
   }
   
   isOpen2D() {
      return isNaN(this.center.x) || isNaN(this.center.y) || isNaN(this.radius);
   }
   isClosed2D() {
      return !this.isOpen2D();
   }
   
   clone() {
      let copy = new BoundingCircle();
      copy.center.x = this.center.x;
      copy.center.y = this.center.y;
      copy.radius   = this.radius;
      return copy;
   }
   
   intersect(other) {
   }
};