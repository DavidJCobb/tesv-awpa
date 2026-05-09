import { distance } from "./vector-ops.js";

export default class Circle {
   constructor(params) {
      this.center = new DOMPoint(0, 0);
      this.radius = 0;
      
      if (params) {
         this.radius   = params.radius;
         this.center.x = params.cx || params.center.x;
         this.center.y = params.cy || params.center.y;
      }
   }
   
   get cx() { return this.center.x; }
   get cy() { return this.center.y; }
   
   static filter_wholly_enveloped_circles(circles) {
      return circles.filter((circle) => {
         for(let other of circles) {
            if (other == circle)
               continue;
            if (circle.contains(other))
               return false;
         }
         return true;
      });
   }
   
   /*bool*/ contains(/*const Variant<Circle, DOMPoint>*/ other) /*const*/ {
      if (other instanceof Circle) {
         if (this.radius < other.radius)
            return false;
         let d = distance(this.center, other.center);
         return d <= this.radius - other.radius;
      }
      let gap = distance(other, this.center) - this.radius;
      return (gap < 0.0001);
   }
   /*bool*/ empty() /*const*/ {
      return this.radius <= 0;
   }
   /*bool*/ equals(other) /*const*/ {
      if (!(other instanceof Circle))
         return false;
      for(let k of ["radius", "cx", "cy"])
         if (this[k] != other[k])
            return false;
      return true;
   }
   
   /*Circle*/ clone() /*const*/ {
      let copy = new Circle();
      copy.center.x = this.center.x;
      copy.center.y = this.center.y;
      copy.radius   = this.radius;
      return copy;
   }
   
   render() {
      const node = document.createElementNS("http://www.w3.org/2000/svg", "circle");
      node.setAttribute("cx", this.cx);
      node.setAttribute("cy", this.cy);
      node.setAttribute("r",  this.radius);
      return node;
   }
};