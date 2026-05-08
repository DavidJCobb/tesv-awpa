export class Bounds {
   constructor() {
      this.min = new DOMPoint(-Infinity, -Infinity, -Infinity);
      this.max = new DOMPoint( Infinity,  Infinity,  Infinity);
   }
   
   equals(other) {
      if (!(other instanceof Bounds))
         return false;
      if (this.min.x != other.min.x)
         return false;
      if (this.max.x != other.max.x)
         return false;
      if (this.min.y != other.min.y)
         return false;
      if (this.max.y != other.max.y)
         return false;
      return true;
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
   
   equals(other) {
      if (!(other instanceof BoundingCircle))
         return false;
      
      let _eq = function(a, b) {
         let na = isNaN(a);
         let nb = isNaN(b);
         if (na != nb)
            return false;
         if (na && nb)
            return true;
         return a == b;
      };
      
      if (!_eq(this.radius, other.radius))
         return false;
      if (!_eq(this.center.x, other.center.x))
         return false;
      if (!_eq(this.center.y, other.center.y))
         return false;
      return true;
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