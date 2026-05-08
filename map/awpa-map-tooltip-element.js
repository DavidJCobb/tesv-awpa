
import svg_viewbox_rect from "./utils/svg_viewbox_rect.js";

export default class AWPAMapTooltipElement extends HTMLElement {
   #current_group;
   #position = {
      canvas: null, // SVG element
      point:  new DOMPoint(NaN, NaN), // coordinates within SVG element's coordinate system
   };
   #shadow;
   
   #canvas_resize_observer;
   
   constructor() {
      super();
      this.#shadow = this.attachShadow({ mode: "open" });
      this.#shadow.innerHTML = `
<link rel="stylesheet" href="./awpa-map-tooltip-element.css" />
<div class="name"></div>
      `;
      
      this.#canvas_resize_observer = new ResizeObserver((entries) => {
         this.#update_css_position();
      });
      
      // TODO
   }
   
   set_anchored(v) {
      // TODO
   }
   
   set_current_group(/*Group*/ g) {
      if (this.#current_group == g)
         return;
      this.#current_group = g;
      if (g) {
         this.classList.add("has-group");
         this.#shadow.querySelector(".name").innerText = g.name || "<unnamed>";
      } else {
         this.classList.remove("has-group");
      }
   }
   
   set_position(canvas, point) {
      const prior_canvas = this.#position.canvas;
      if (prior_canvas != canvas) {
         this.#position.canvas = canvas;
         this.#canvas_resize_observer.disconnect();
         if (canvas) {
            this.#canvas_resize_observer.observe(canvas, {});
         }
      }
      this.#position.point = new DOMPoint(point.x, point.y);
      this.#update_css_position();
   }
   
   #update_css_position() {
      const canvas = this.#position.canvas;
      if (!canvas)
         return;
      const canvas_pos = this.#position.point;
      if (isNaN(canvas_pos.x) || isNaN(canvas_pos.y))
         return;
      
      let viewbox = svg_viewbox_rect(canvas);
      let display = canvas.getBoundingClientRect();
      let ratio_x = viewbox.width  / display.width;
      let ratio_y = viewbox.height / display.height;
      
      let screen_x =  canvas_pos.x;
      let screen_y = -canvas_pos.y;
      screen_x -= viewbox.left;
      screen_y -= viewbox.top;
      screen_x /= ratio_x;
      screen_y /= ratio_y;
      
      screen_x += 32; // ensure it doesn't block the cursor
      
      let style = this.style;
      style.setProperty("--x", `${screen_x}px`);
      style.setProperty("--y", `${screen_y}px`);
   }
};
window.customElements.define("awpa-map-tooltip", AWPAMapTooltipElement);

/*
   TODO: Desired behavior:
   
    - Mouseover a group: show the group name as a tooltip
    
    - Click a group: anchor the tooltip, and display the lines in a scrollable pain inside
    
    - Click anywhere that isn't a group: un-anchor the tooltip
    
    - Right-click the map while the tooltip is anchored: un-anchor the tooltip
*/