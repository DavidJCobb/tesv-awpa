import Ref from "./data-ref.js"

export default class Place {
   constructor(node) {
      this.owner      = null; // AWPAMap
      this.name       = "";
      this.grid_rect  = null;
      this.refs       = [];
      this.refs_by_id = new Map(); // Map<int form_id, Ref>
      
      this.svg_paths = [];
      
      if (node) {
         this.#from_data_node(node);
      }
   }
   
   #from_data_node(node) {
      this.name = node.getAttribute("name") || "";
      node.querySelectorAll("ref").forEach((src) => {
         let ref = new Ref(src);
         ref.owner = this;
         this.refs.push(ref);
         if (ref.form_id)
            this.refs_by_id.set(ref.form_id, ref);
      });
      
      node.querySelectorAll("wall[d]").forEach((src) => {
         let path = document.createElementNS("http://www.w3.org/2000/svg", "path");
         path.classList.add("wall");
         path.setAttribute("d", src.getAttribute("d"));
         this.svg_paths.push(path);
      });
      node.querySelectorAll("svg").forEach((src) => {
         //
         // For whatever reason, bringing in the `svg` node directly causes it to 
         // fail to render when we zoom into Windhelm, in at least some situations.
         //
         let g = document.createElementNS("http://www.w3.org/2000/svg", "g");
         for(let child of src.children)
            g.append(document.importNode(child, true));
         this.svg_paths.push(g);
      });
      
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
};