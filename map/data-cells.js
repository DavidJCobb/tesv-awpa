
export class Cell {
   constructor() {
      this.form_id  = null; // int
      this.grid_pos = null; // DOMPoint
      this.location = null; // Optional<String editor_id>
   }
};

export class CellMap {
   #cells = new Map(); // map<int form_id, Cell>
   
   constructor() {
   }
   
   load(data_root_node) {
      data_root_node.querySelectorAll("cells>location").forEach((node) => {
         let location = node.getAttribute("editor-id");
         node.querySelectorAll("cell").forEach((node) => {
            let pos  = node.getAttribute("coords").split(",");
            let cell = new Cell();
            cell.form_id  = parseInt(node.getAttribute("form-id"), 16);
            cell.grid_pos = new DOMPoint(+pos[0], +pos[1]);
            cell.location = location;
            this.#cells.set(cell.form_id, cell);
         });
      });
   }
   
   for_each_cell(f) {
      this.#cells.forEach(f);
   }
};