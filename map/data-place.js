import Ref from "./data-ref.js"

export default class Place {
   constructor(node) {
      this.owner     = null; // AWPAMap
      this.name      = "";
      this.grid_rect = null;
      this.refs      = [];
      if (node) {
         this.#from_data_node(node);
      }
   }
   
   #from_data_node(node) {
      this.name = node.getAttribute("name") || "";
      node.querySelectorAll("ref").forEach((function(src) {
         let ref = new Ref(src);
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
};