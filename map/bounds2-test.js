import { AABB, Bounds, Circle } from "./bounds2.js";
import svg_viewbox_rect from "./utils/svg_viewbox_rect.js";

let svg = document.querySelector("svg");

function do_testcase(circles) {
   let svg_w;
   let svg_h;
   {
      let vb = svg.getAttribute("viewBox").trim().split(" ");
      svg_w = +vb[2];
      svg_h = +vb[3];
   }
   svg.replaceChildren();
   for(let i = 0; i < svg_w; ++i) {
      let line = document.createElementNS("http://www.w3.org/2000/svg", "line");
      line.setAttribute("x1", i);
      line.setAttribute("x2", i);
      line.setAttribute("y1", 0);
      line.setAttribute("y2", svg_h);
      if (!(i % 10))
         line.classList.add("ten");
      svg.append(line);
   }
   for(let i = 0; i < svg_h; ++i) {
      let line = document.createElementNS("http://www.w3.org/2000/svg", "line");
      line.setAttribute("y1", i);
      line.setAttribute("y2", i);
      line.setAttribute("x1", 0);
      line.setAttribute("x2", svg_w);
      if (!(i % 10))
         line.classList.add("ten");
      svg.append(line);
   }
   
   for(let circle of circles) {
      let node = document.createElementNS("http://www.w3.org/2000/svg", "circle");
      node.setAttribute("cx", circle.cx);
      node.setAttribute("cy", circle.cy);
      node.setAttribute("r",  circle.radius);
      svg.append(node);
   }
   
   let bounds = new Bounds();
   bounds.circles = ([]).concat(circles);
   console.log(bounds);
   {
      let node = bounds.render();
      if (node) {
         node.classList.add("result");
         svg.append(node);
      }
   }
}

function randomize() {
   let svg_w;
   let svg_h;
   {
      let vb = svg.getAttribute("viewBox").trim().split(" ");
      svg_w = +vb[2];
      svg_h = +vb[3];
   }
   
   let circles = [];
   
   let first;
   {
      let radius = Math.round(Math.random() * 8 + 2);
      let cx     = Math.floor(Math.random() * (svg_w - radius * 2) + radius);
      let cy     = Math.floor(Math.random() * (svg_h - radius * 2) + radius);
      
      first = new Circle();
      first.radius = radius;
      first.center = new DOMPoint(cx, cy);
      circles.push(first);
   }
   
   for(let i = 0; i < 2; ++i) {
      let radius   = Math.round(Math.random() * 8 + 2);
      
      let distance = Math.random() * Math.max(radius, first.radius);
      let angle    = Math.random() * 2 * Math.PI;
      
      let cx = Math.cos(angle) * distance + first.cx;
      let cy = Math.sin(angle) * distance + first.cy;
      
      let circle = new Circle();
      circle.radius = radius;
      circle.center = new DOMPoint(cx, cy);
      circles.push(circle);
   }
   
   do_testcase(circles);
}

const TESTCASES = {
   "only two points, circle order AB": {
      circles: [
         new Circle({ radius: 10, cx: 19, cy: 24 }),
         new Circle({ radius:  7, cx: 21, cy: 32 }),
         new Circle({ radius:  4, cx: 18, cy: 26 }),
      ],
   },
   "cannot shortest arc": {
      circles: [
         new Circle({ radius:  9, cx: 19, cy: 39 }),
         new Circle({ radius: 10, cx: 20, cy: 42 }),
         new Circle({ radius:  8, cx: 28, cy: 39 }),
      ],
   },
   "requires large arc flag to draw": {
      circles: [
         new Circle({ radius:  7, cx: 10, cy: 31 }),
         new Circle({ radius:  3, cx: 12, cy: 26 }),
         new Circle({ radius:  9, cx: 10, cy: 31 }),
      ],
   },
   "only two points, circle order BA": {
      circles: [
         new Circle({ radius:  6, cx: 19, cy: 29 }),
         new Circle({ radius:  5, cx: 22, cy: 30 }),
         new Circle({ radius:  3, cx: 18, cy: 31 }),
      ],
   },
   "all circles inside of largest": {
      circles: [
         new Circle({ radius:  6, cx: 8, cy: 29 }),
         new Circle({ radius:  5, cx: 8, cy: 29 }),
         new Circle({ radius:  9, cx: 9, cy: 29 }),
      ],
   },
   "pathological 6": {
      circles: [
         new Circle({ radius:  6, cx: 11, cy: 30 }),
         new Circle({ radius:  8, cx: 13, cy: 29 }),
         new Circle({ radius: 10, cx: 16, cy: 29 }),
      ],
   },
   "pathological 7": {
      circles: [
         new Circle({ radius:  8, cx: 21, cy: 36 }),
         new Circle({ radius:  7, cx: 18, cy: 35 }),
         new Circle({ radius:  6, cx: 20, cy: 37 }),
      ],
   },
   "pathological 8": {
      circles: [
         new Circle({ radius:  4, cx: 23, cy: 32.5 }),
         new Circle({ radius:  9, cx: 20, cy: 37 }),
         new Circle({ radius:  5, cx: 23, cy: 32 }),
      ],
   },
};

{
   let node = document.querySelector("section");
   for(let name in TESTCASES) {
      let button = document.createElement("input");
      button.setAttribute("type", "button");
      button.setAttribute("value", name);
      button.setAttribute("data-testcase", name);
      node.append(button);
   }
}

document.querySelector("input[type='button'][data-testcase='random']").addEventListener("click", randomize);
document.querySelectorAll("input[type='button']:not([data-testcase='random'])").forEach((node) => {
   node.addEventListener("click", function(e) {
      let testcase = TESTCASES[e.target.getAttribute("data-testcase")];
      do_testcase(testcase.circles);
   });
});

randomize();