
const SVG_NAMESPACE = "http://www.w3.org/2000/svg";

class AWPARef {
   constructor(node) {
      this.owner  = null; // AWPAPlace
      this.name   = node?.getAttribute("name") || "";
      this.pos    = { x: 0, y: 0 };
      this.base   = null;
      this.bounds = null;
      if (node) {
         this.name = node.getAttribute("label") || "";
         let src_pos = node.getAttribute("pos")?.split(",");
         this.pos   = {
            x: +src_pos[0],
            y: +src_pos[1],
         };
         this.yaw = +node.getAttribute("yaw") || 0;
         
         let base = node.getAttribute("base");
         if (base)
            this.base = base;
         else {
            let obnd = node.querySelector("obnd");
            if (obnd) {
               let x = obnd.getAttribute("x").split(",");
               let y = obnd.getAttribute("y").split(",");
               this.bounds = {
                  x: { min: +x[0], max: +x[1] },
                  y: { min: +y[0], max: +y[1] },
               };
            }
         }
      }
   }
   
   /*Element*/ render() {
      let node = document.createElementNS(SVG_NAMESPACE, "g");
      //let node = document.createElement("rect");
      node.classList.add("ref");
      if (this.name)
         node.setAttribute("data-name", this.name);
      let style = node.style;
      style.setProperty("--x",   this.pos.x);
      style.setProperty("--y",   this.pos.y);
      style.setProperty("--yaw", this.yaw);
      
      let x_span;
      let y_span;
      if (this.base) {
         if (this.owner?.owner) {
            let base = this.owner.owner.base_form_by_id(this.base);
            if (base) {
               x_span = base.x;
               y_span = base.y;
            }
         }
      } else if (this.bounds) {
         x_span = this.bounds.x;
         y_span = this.bounds.y;
      }
      if (x_span && y_span) {
         let obnd = document.createElementNS(SVG_NAMESPACE, "rect");
         node.append(obnd);
         obnd.classList.add("obnd");
         let style = obnd.style;
         style.setProperty("--obnd-x-min", x_span.min);
         style.setProperty("--obnd-x-max", x_span.max);
         style.setProperty("--obnd-y-min", y_span.min);
         style.setProperty("--obnd-y-max", y_span.max);
      }
      
      return node;
   }
};

class AWPAPlace {
   constructor(node) {
      this.owner     = null; // AWPAMap
      this.name      = "";
      this.grid_rect = null;
      this.refs      = [];
      if (node) {
         this.name = node.getAttribute("name") || "";
         node.querySelectorAll("ref").forEach((function(src) {
            let ref = new AWPARef(src);
            ref.owner = this;
            this.refs.push(ref);
         }).bind(this));
         
         let grid = node.querySelector("grid-rect");
         if (grid) {
            let min = grid.getAttribute("min").split(",");
            let max = grid.getAttribute("max").split(",");
            this.grid_rect = new DOMRect(
               +min[0],
               +min[1],
               (+max[0] - min[0]),
               (+max[1] - min[1])
            );
         }
      }
   }
};

class AWPAMapElement extends HTMLElement {
   #shadow;
   #sidebar;
   #status_bar;
   #svg;
   #svg_container_nodes = {
      cells: null,
   };
   
   #data_observer;
   
   #base_forms = {};
   #cells      = {};
   #places     = {};
   
   constructor() {
      super();
      
      this.grid = {
         // BUG: if these aren't symmetric, the CSS we use to display refs gets fucked up.
         //      See CSS stylesheet comments.
         min: new DOMPoint(-50, -30),
         max: new DOMPoint( 50,  30)
      };
      
      this.#shadow = this.attachShadow({ mode: "open" });
      {
         let link = document.createElement("link");
         link.setAttribute("rel", "stylesheet");
         link.setAttribute("href", "awpa-map-element.css");
         this.#shadow.append(link);
      }
      
      this.#svg = document.createElementNS(SVG_NAMESPACE, "svg");
      this.#shadow.append(this.#svg);
      this.#svg.append(document.createElementNS(SVG_NAMESPACE, "defs"));
      
      this.#on_mutated_bound = this.#on_mutated.bind(this);
      this.#data_observer = new MutationObserver(this.#on_mutated_bound);
      this.#data_observer.observe(this, { childList: true });
      
      {
         let node = document.createElementNS(SVG_NAMESPACE, "g");
         node.id = "cells";
         this.#svg.append(node);
         this.#svg_container_nodes.cells = node;
      }
      
      {
         let w_px = (this.grid.max.x - this.grid.min.x + 1) * 4096;
         let h_px = (this.grid.max.y - this.grid.min.y + 1) * 4096;
         this.view_place("");
         {
            let path = document.createElementNS(SVG_NAMESPACE, "path");
            this.#svg.append(path);
            path.classList.add("gridlines");
            
            let d = `M ${this.grid.min.x*4096} ${-this.grid.max.y*4096} l0,${h_px} `;
            for(let x = this.grid.min.x + 1; x <= this.grid.max.x + 1; ++x) {
               d += `m 4096,${-h_px} l0,${h_px} `;
            }
            d += `M ${this.grid.min.x*4096} ${-this.grid.max.y*4096} l${w_px},0 `;
            for(let y = this.grid.min.y + 1; y <= this.grid.max.y + 1; ++y) {
               d += `m ${-w_px},4096 l${w_px},0 `;
            }
            path.setAttribute("d", d);
         }
      }
      
      this.#sidebar = document.createElement("div");
      this.#shadow.append(this.#sidebar);
      this.#sidebar.classList.add("sidebar");
      this.#sidebar.innerHTML = `
<header>
   Map
</header>
<section class="rows">
   <div>
      <label><input id="show-grid" type="checkbox" /> Show grid</label>
   </div>
</section>
<section>
   <header>
      Views
   </header>
   <ul class="body" id="view-list">
      <li data-view-name="">All</li>
   </ul>
</section>
      `;
      
      this.#status_bar = document.createElement("div");
      this.#shadow.append(this.#status_bar);
      this.#status_bar.classList.add("status-bar");
      this.#status_bar.innerHTML = `
<div class="segment" id="grid-coords">
   &lt;no cell&gt;
</div>
<div class="segment" id="current-ref">
   &lt;no ref&gt;
</div>
      `;
      
      this.#sidebar.querySelector("#show-grid").addEventListener("change", (function(e) {
         this.#svg.classList.toggle("show-grid");
      }).bind(this));
      this.#sidebar.querySelector("#view-list").addEventListener("click", (function(e) {
         let item = e.target.closest("#view-list li");
         if (!item)
            return;
         this.view_place(item.getAttribute("data-view-name"));
      }).bind(this));
      
      this.#svg.addEventListener("mouseover",  this.#on_svg_mouseover.bind(this));
      this.#svg.addEventListener("mousemove",  this.#on_svg_mousemove.bind(this));
      this.#svg.addEventListener("mouseout",   this.#on_svg_mouseout.bind(this));
   }
   
   base_form_by_id(id) {
      return this.#base_forms[id];
   }
   
   #on_mutated_bound;
   #on_mutated(records) {
      for(let record of records) {
         for(let node of record.addedNodes) {
            if (node.nodeName.toLowerCase() == "template") {
               this.#load(node);
               this.#data_observer.disconnect();
               return;
            }
         }
      }
   }
   
   #canvas_rect() {
      let view_box = this.#svg.getAttribute("viewBox").split(" ");
      return new DOMRect(
         +view_box[0],
         +view_box[1],
         +view_box[2],
         +view_box[3]
      );
   }
   
   pixels_to_world_units(x, y, viewport_relative) {
      let disp_rect = this.#svg.getBoundingClientRect();
      let real_rect = this.#canvas_rect();
      let x_scale = disp_rect.width  / real_rect.width;
      let y_scale = disp_rect.height / real_rect.height;
      
      if (viewport_relative) {
         x -= disp_rect.left;
         y -= disp_rect.top;
      }
      x =   x / x_scale + real_rect.x;
      y = -(y / y_scale + real_rect.y);
      return [x, y];
   }
   pixels_to_grid_units(x, y, viewport_relative) {
      let wu = this.pixels_to_world_units(x, y, viewport_relative);
      let grid_x = Math.floor(wu[0]);
      let grid_y = Math.floor(wu[1]) + 4095;
      grid_x /= 4096;
      grid_y /= 4096;
      grid_x = Math.floor(grid_x);
      grid_y = Math.floor(grid_y);
      return [grid_x, grid_y];
   }
   world_units_to_pixels(x, y, viewport_relative) {
      let disp_rect = this.#svg.getBoundingClientRect();
      let real_rect = this.#canvas_rect();
      let x_scale = disp_rect.width  / real_rect.width;
      let y_scale = disp_rect.height / real_rect.height;
      
      y = -y;
      x = (x + real_rect.x) * x_scale;
      y = (y + real_rect.y) * y_scale;
      if (viewport_relative) {
         x += disp_rect.left;
         y += disp_rect.top;
      }
      return [x, y];
   }
   grid_units_to_pixels(x, y, viewport_relative) {
      x *= 4096;
      y *= 4096;
      return this.world_units_to_pixels(x, y, viewport_relative);
   }
   
   #on_svg_mouseover(e) {
      let display = this.#shadow.querySelector("#current-ref");
      let subject = e.target.closest(".ref");
      if (subject) {
         let name = subject.getAttribute("data-name");
         if (name) {
            display.textContent = name;
            return;
         }
      }
      display.textContent = "<no ref>";
   }
   #on_svg_mousemove(e) {
      let [grid_x, grid_y] = this.pixels_to_grid_units(e.clientX, e.clientY, true);
      let node = this.#shadow.querySelector("#grid-coords");
      node.textContent = `(${grid_x}, ${grid_y})`;
   }
   #on_svg_mouseout(e) {
      this.#shadow.querySelector("#grid-coords").textContent = "<no cell>";
      this.#shadow.querySelector("#current-ref").textContent = "<no ref>";
   }
   
   view_place(name) {
      let min = this.grid.min;
      let max = this.grid.max;
      if (name) {
         let place = this.#places[name];
         if (place && place.grid_rect) {
            let rect = place.grid_rect;
            min = new DOMPoint(rect.left, rect.top);
            max = new DOMPoint(rect.right, rect.bottom);
         }
      }
      this.#svg.setAttribute("viewBox", `${min.x*4096} ${min.y*4096} ${(max.x-min.x+1)*4096} ${(max.y-min.y+1)*4096}`);
   }
   
   #load(template_node) {
      let root = document.importNode(template_node.content, true);
      root.querySelectorAll("bounds>bound[id]").forEach((function (node) {
         let id   = node.getAttribute("id");
         let x    = node.getAttribute("x").split(",");
         let y    = node.getAttribute("y").split(",");
         let base = this.#base_forms[id];
         if (!base)
            base = this.#base_forms[id] = { id: id };
         base.x = { min: +x[0], max: +x[1] };
         base.y = { min: +y[0], max: +y[1] };
      }).bind(this));
      root.querySelectorAll("cells>location").forEach((function(node) {
         let location = node.getAttribute("editor-id");
         node.querySelectorAll("cell").forEach((function(node) {
            let pos  = node.getAttribute("coords").split(",");
            let cell = {
               x:        +pos[0],
               y:        +pos[1],
               form_id:  parseInt(node.getAttribute("form-id"),16),
               location: location,
            };
            this.#cells[cell.form_id] = cell;
         }).bind(this));
      }).bind(this));
      root.querySelectorAll("places>place").forEach((function(node) {
         let place = new AWPAPlace(node);
         place.owner = this;
         this.#places[place.name] = place;
         if (place.grid_rect) {
            let li = document.createElement("li");
            li.textContent = place.name;
            li.setAttribute("data-view-name", place.name);
            this.#sidebar.querySelector("#view-list").append(li);
         }
      }).bind(this));
      
      //
      // Render:
      //
      
      for(let form_id in this.#cells) {
         let cell = this.#cells[form_id];
         let node = document.createElementNS(SVG_NAMESPACE, "rect");
         node.style.setProperty("--x", cell.x);
         node.style.setProperty("--y", cell.y);
         node.setAttribute("data-form-id", cell.form_id);
         node.setAttribute("data-location-name", cell.location);
         this.#svg_container_nodes.cells.append(node);
      }
      
      for(let key in this.#places) {
         let place = this.#places[key];
         for(let ref of place.refs) {
            let node = ref.render();
            this.#svg.append(node);
         }
      }
   }
};
window.customElements.define("awpa-map", AWPAMapElement);