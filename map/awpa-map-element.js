
import { Cell, CellMap } from "./data-cells.js";
import Ref   from "./data-ref.js";
import Place from "./data-place.js";

import svg_viewbox_rect from "./utils/svg_viewbox_rect.js";

import "./awpa-map-tooltip-element.js";

const CELL_SIZE_WU  = 4096;
const SVG_NAMESPACE = "http://www.w3.org/2000/svg";

class AWPAMapElement extends HTMLElement {
   #shadow;
   #sidebar;
   #status_bar;
   #svg;
   #svg_container_nodes = {
      cells:  null,
      refs:   null,
      groups: null,
   };
   #tooltip;
   
   #base_forms = {};
   #cells      = new CellMap();
   #groups     = null; // Optional<GroupCollection>
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
      this.#shadow.innerHTML = `
<link rel="stylesheet" href="./awpa-map-element.css" />
<svg xmlns="http://www.w3.org/2000/svg">
   <defs>
   </defs>
   <g id="cells">
   </g>
   <g id="groups">
   </g>
   <g id="refs">
   </g>
</svg>
<div class="sidebar">
   <header>Map</header>
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
   <section>
      <header>
         AWPA payloads
      </header>
      <div class="body">
         <slot name="payload-uploads"></slot>
      </div>
   </section>
</div>
<div class="status-bar">
   <div class="segment" id="grid-coords">&lt;no cell&gt;</div>
   <div class="segment" id="current-ref">&lt;no ref&gt;</div>
</div>
<awpa-map-tooltip></awpa-map-tooltip>
      `;
      this.#svg = this.#shadow.querySelector("svg");
      this.#svg_container_nodes.cells  = this.#svg.querySelector("#cells");
      this.#svg_container_nodes.refs   = this.#svg.querySelector("#refs");
      this.#svg_container_nodes.groups = this.#svg.querySelector("#groups");
      {
         let w_px = (this.grid.max.x - this.grid.min.x + 1) * CELL_SIZE_WU;
         let h_px = (this.grid.max.y - this.grid.min.y + 1) * CELL_SIZE_WU;
         this.view_place("");
         {
            let path = document.createElementNS(SVG_NAMESPACE, "path");
            this.#svg.append(path);
            path.classList.add("gridlines");
            
            let d = `M ${this.grid.min.x*CELL_SIZE_WU} ${-this.grid.max.y*CELL_SIZE_WU} l0,${h_px} `;
            for(let x = this.grid.min.x + 1; x <= this.grid.max.x + 1; ++x) {
               d += `m ${CELL_SIZE_WU},${-h_px} l0,${h_px} `;
            }
            d += `M ${this.grid.min.x*CELL_SIZE_WU} ${-this.grid.max.y*CELL_SIZE_WU} l${w_px},0 `;
            for(let y = this.grid.min.y + 1; y <= this.grid.max.y + 1; ++y) {
               d += `m ${-w_px},${CELL_SIZE_WU} l${w_px},0 `;
            }
            path.setAttribute("d", d);
         }
      }
      
      this.#tooltip = this.#shadow.querySelector("awpa-map-tooltip");
      this.#tooltip.style.display = "none";
      
      this.#sidebar    = this.#shadow.querySelector(".sidebar");
      this.#status_bar = this.#shadow.querySelector(".status-bar");
      
      this.#sidebar.querySelector("#show-grid").addEventListener("change", (e) => {
         this.set_show_grid(e.target.checked);
      });
      this.#sidebar.querySelector("#view-list").addEventListener("click", (e) => {
         let item = e.target.closest("#view-list li");
         if (!item)
            return;
         this.view_place(item.getAttribute("data-view-name"));
      });
      
      this.#svg.addEventListener("mouseover",  this.#on_svg_mouseover.bind(this));
      this.#svg.addEventListener("mousemove",  this.#on_svg_mousemove.bind(this));
      this.#svg.addEventListener("mouseout",   this.#on_svg_mouseout.bind(this));
      
      this.set_show_grid(true);
   }
   
   set_show_grid(v) {
      this.#sidebar.querySelector("#show-grid").checked = v;
      this.#svg.classList[v ? "add" : "remove"]("show-grid");
   }
   
   set_group_collection(coll) {
      if (this.#groups === coll)
         return;
      this.#groups = coll;
      
      this.#svg_container_nodes.groups.replaceChildren();
      
      let list = coll.groups.flat_exterior;
      for(let i = list.length - 1; i >= 0; --i) {
         let group = list[i];
         let node  = group.render();
         this.#svg_container_nodes.groups.append(node);
      }
   }
   
   async connectedCallback() {
      let response = await fetch("./data.xml");
      let text     = await response.text();
      let dom      = (new DOMParser()).parseFromString(text, "application/xml");
      
      let root = dom.documentElement;
      root.querySelectorAll("bounds>bound[id]").forEach((node) => {
         let id   = node.getAttribute("id");
         let x    = node.getAttribute("x").split(",");
         let y    = node.getAttribute("y").split(",");
         let base = this.#base_forms[id];
         if (!base)
            base = this.#base_forms[id] = { id: id };
         base.x = { min: +x[0], max: +x[1] };
         base.y = { min: +y[0], max: +y[1] };
      });
      this.#cells.load(root);
      root.querySelectorAll("places>place").forEach((node) => {
         let place = new Place(node);
         place.owner = this;
         this.#places[place.name] = place;
         if (place.grid_rect) {
            let li = document.createElement("li");
            li.textContent = place.name;
            li.setAttribute("data-view-name", place.name);
            this.#sidebar.querySelector("#view-list").append(li);
         }
      });
      
      //
      // Render:
      //
      
      this.#cells.for_each_cell((cell) => {
         let node = document.createElementNS(SVG_NAMESPACE, "rect");
         node.style.setProperty("--x", cell.grid_pos.x);
         node.style.setProperty("--y", cell.grid_pos.y);
         node.setAttribute("data-form-id",       cell.form_id);
         node.setAttribute("data-location-name", cell.location);
         this.#svg_container_nodes.cells.append(node);
      });
      
      for(let key in this.#places) {
         let place = this.#places[key];
         for(let ref of place.refs) {
            let node = ref.render();
            this.#svg_container_nodes.refs.append(node);
         }
      }
   }
   
   base_form_by_id(id) {
      return this.#base_forms[id];
   }
   
   #canvas_rect() {
      return svg_viewbox_rect(this.#svg);
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
      return this.world_units_to_grid_units(wu[0], wu[1]);
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
   world_units_to_grid_units(x, y) {
      let grid_x = Math.floor(x);
      let grid_y = Math.floor(y) + (CELL_SIZE_WU - 1);
      grid_x /= CELL_SIZE_WU;
      grid_y /= CELL_SIZE_WU;
      grid_x = Math.floor(grid_x);
      grid_y = Math.floor(grid_y);
      return [grid_x, grid_y];
   }
   grid_units_to_pixels(x, y, viewport_relative) {
      x *= CELL_SIZE_WU;
      y *= CELL_SIZE_WU;
      return this.world_units_to_pixels(x, y, viewport_relative);
   }
   
   #on_svg_mouseover(e) {
      {  // ref name
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
   }
   #on_svg_mousemove(e) {
      let [world_x, world_y] = this.pixels_to_world_units(e.clientX, e.clientY, true);
      let [grid_x,  grid_y]  = this.world_units_to_grid_units(world_x, world_y);
      {
         let node = this.#shadow.querySelector("#grid-coords");
         node.textContent = `(${grid_x}, ${grid_y})`;
      }
      
      let   is_over_group = false;
      const elements      = this.#shadow.elementsFromPoint(e.clientX, e.clientY);
      for(const element of elements) {
         if (element.matches("#groups [data-name]")) {
            this.#tooltip.set_position(this.#svg, new DOMPoint(world_x, world_y));
            this.#tooltip.set_current_group(element.source_data);
            this.#tooltip.style.display = "";
            is_over_group = true;
            break;
         }
      }
      if (!is_over_group) {
         this.#tooltip.style.display = "none";
      }
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
      this.#svg.setAttribute("viewBox", `${min.x*CELL_SIZE_WU} ${min.y*CELL_SIZE_WU} ${(max.x-min.x+1)*CELL_SIZE_WU} ${(max.y-min.y+1)*CELL_SIZE_WU}`);
   }
};
window.customElements.define("awpa-map", AWPAMapElement);