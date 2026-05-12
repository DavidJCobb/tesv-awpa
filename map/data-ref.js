
export default class Ref {
   constructor(node) {
      this.owner   = null; // AWPAPlace
      this.name    = node?.getAttribute("name") || "";
      this.pos     = { x: 0, y: 0 };
      this.base    = null;
      this.bounds  = null;
      this.form_id = null; // Optional<int>
      if (node) {
         this.#from_data_node(node);
      }
   }
   
   #from_data_node(node) {
      let src_pos = node.getAttribute("pos")?.split(",");
      
      this.name = node.getAttribute("label") || "";
      this.pos  = new DOMPoint(+src_pos[0], +src_pos[1]);
      this.yaw  = +node.getAttribute("yaw") || 0;
      
      {
         let id = node.getAttribute("form-id");
         if (id) {
            id = parseInt(id, 16);
            if (id)
               this.form_id = id;
         }
      }
      
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
   
   /*Element*/ render() {
      let node = document.createElementNS("http://www.w3.org/2000/svg", "g");
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
         let obnd = document.createElementNS("http://www.w3.org/2000/svg", "rect");
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