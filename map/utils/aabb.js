export default class AABB {
   constructor() {
      this.min = new DOMPoint(-Infinity, -Infinity, -Infinity);
      this.max = new DOMPoint( Infinity,  Infinity,  Infinity);
   }
   
   get x() { return this.min.x; }
   get y() { return this.min.y; }
   get z() { return this.min.z; }
   get width() { return this.max.x - this.min.x; }
   get height() { return this.max.y - this.min.y; }
   get depth() { return this.max.z - this.min.z; }
   
   get center() {
      return new DOMPoint(this.x + this.width / 2, this.y + this.height / 2);
   }
   
   /*bool*/ empty() /*const*/ {
      for(const axis of ["x", "y", "z"]) {
         if (this.min[axis] < this.max[axis])
            return false;
      }
      return true;
   }
   /*bool*/ equals(/*const AABB*/ other) /*const*/ {
      if (!(other instanceof AABB))
         return false;
      for(const u of ["min", "max"]) {
         const a = this[u];
         const b = other[u];
         for(const v of ["x", "y", "z"])
            if (a[v] != b[v])
               return false;
      }
      return true;
   }
   
   /*DOMRect*/ toDOMRect() /*const*/ {
      return new DOMRect(this.min.x, this.min.y, this.width, this.height);
   }
   
   /*bool*/ isOpen2D() /*const*/ {
      return !isFinite(this.width) || !isFinite(this.height);
   }
   /*bool*/ isClosed2D() /*const*/ {
      return isFinite(this.width) && isFinite(this.height);
   }
   
   /*AABB*/ clone() /*const*/ {
      let copy = new AABB();
      for(const u of ["min", "max"]) {
         const src = this[u];
         const dst = copy[u];
         for(const v of ["x", "y", "z"])
            dst[v] = src[b];
      }
      return copy;
   }
   intersect(/*const AABB*/ other) {
      if (!(other instanceof AABB))
         return;
      this.min.x = Math.max(this.min.x, other.min.x);
      this.min.y = Math.max(this.min.y, other.min.y);
      this.min.z = Math.max(this.min.z, other.min.z);
      this.max.x = Math.min(this.max.x, other.max.x);
      this.max.y = Math.min(this.max.y, other.max.y);
      this.max.z = Math.min(this.max.z, other.max.z);
   }
   
   render() {
      const node = document.createElementNS("http://www.w3.org/2000/svg", "rect");
      for(let name of ["x", "y", "width", "height"])
         node.setAttribute(name, this[name]);
      return node;
   }
};