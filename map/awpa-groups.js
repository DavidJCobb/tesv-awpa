import { Bounds, BoundingCircle } from "./bounds.js";

export class Group {
   constructor() {
      this.conditions = {
         bounds:             new Bounds(),
         distance: {
            ref:    null, // Optional<int form_id>
            radius: 0,
         },
         confirmed_exterior: false,
         confirmed_interior: false,
      };
      this.children  = []; // Array<Group>
      this.constants = new Map(); // Map<String, Number>
      this.name      = "";
      this.parent    = null;
      this.lines     = []; // Array<String>
      this.invokes   = false;
   }
   
   static from_node(node, parent) {
      let g = new Group();
      g.parent = parent || null;
      g.#load(node);
      return g;
   }
   
   get computed_bounds() {
      let bounds = this.conditions.bounds.clone();
      let parent = this.parent;
      while (parent && bounds.isOpen2D()) {
         bounds.intersect(parent.conditions.bounds);
         parent = parent.parent;
      }
      return bounds;
   }
   get computed_name() {
      if (this.name)
         return this.name;
      if (!this.parent)
         return "";
      let i = this.parent.children.indexOf(this);
      if (i < 0) // should never happen
         return "";
      let pn = this.parent.computed_name;
      if (pn)
         return pn + `[${i}]`;
      return "";
   }
   
   resolve_constant(v) {
      if (!isNaN(+v))
         return +v;
      let cv = this.constants.get(v);
      if (cv || cv === 0)
         return cv;
      if (this.parent)
         return this.parent.resolve_constant(v);
      return null;
   }
   
   #load(node) {
      this.name = node.getAttribute("name") || "";
      
      let c_node = node.querySelector(":scope>conditions");
      if (c_node) {
         for(let child of c_node.children) {
            switch (child.nodeName) {
               case "x":
               case "y":
               case "z":
                  {
                     let bmin = this.conditions.bounds.min;
                     let bmax = this.conditions.bounds.max;
                     
                     const axis = child.nodeName;
                     if (child.getAttribute("of") != "subject")
                        break;
                     let v = child.getAttribute("eq");
                     if (v) {
                        v = this.resolve_constant(v);
                        if (v === null)
                           break;
                        bmin[axis] = v;
                        bmax[axis] = v;
                        break;
                     }
                     v = child.getAttribute("lte") || child.getAttribute("lt");
                     if (v) {
                        v = this.resolve_constant(v);
                        if (v === null)
                           break;
                        bmax[axis] = Math.min(v, bmax[axis]);
                        break;
                     }
                     v = child.getAttribute("gte") || child.getAttribute("gt");
                     if (v) {
                        v = this.resolve_constant(v);
                        if (v === null)
                           break;
                        bmin[axis] = Math.max(v, bmin[axis]);
                        break;
                     }
                  }
                  break;
               case "distance":
                  {
                     if (child.getAttribute("of") != "subject")
                        break;
                     let radius = child.getAttribute("lte") || child.getAttribute("lt");
                     if (!radius)
                        break;
                     radius = this.resolve_constant(radius);
                     if (radius === null)
                        break;
                     {
                        let to = child.getAttribute("to");
                        let match = to.match(/^\[....:([0-9A-Fa-f]{1,8})\]/);
                        if (!match)
                           break;
                        let id = parseInt(match[1],16);
                        if (id) {
                           this.conditions.distance.ref    = id;
                           this.conditions.distance.radius = radius;
                        }
                     }
                     //
                     // TODO: attr `to` is of the form "[REFR:00123456]EditorID"
                     //
                     // that data belongs to the AWPA map widget. how do we get it here?
                     //
                     let bounds = new BoundingCircle();
                     bounds.radius = radius;
                     this.conditions.bounds = bounds;
                  }
                  break;
               case "parent-cell":
               case "is-in-interior":
                  this.conditions.confirmed_interior = true;
                  break;
               case "parent-world":
               case "is-in-exterior":
                  this.conditions.confirmed_exterior = true;
                  break;
                  
               case "or":
                  {
                     for(let nested of child.children) {
                        switch (nested.nodeName) {
                           case "parent-cell":
                           case "is-in-interior":
                              this.conditions.confirmed_interior = true;
                              break;
                           case "parent-world":
                           case "is-in-exterior":
                              this.conditions.confirmed_exterior = true;
                              break;
                        }
                     }
                  }
                  break;
            }
         }
      }
      for(let child of node.children) {
         switch (child.nodeName) {
            case "conditions":
               break;
            case "g":
            case "top-g":
               {
                  let g = Group.from_node(child, this);
                  g.parent = this;
                  this.children.push(g);
               }
               break;
            case "constant":
               {
                  let name = child.getAttribute("name");
                  let v    = +child.getAttribute("value");
                  this.constants.set(name, v);
               }
               break;
            case "line":
               this.lines.push(child.textContent);
               break;
            case "shared-info":
               this.lines.push(`<shared-info id="${child.getAttribute("id")}" />`);
               break;
            case "invoke":
               this.invokes = true;
               // TODO
               break;
         }
      }
   }
   
   render() {
      let bounds = this.conditions.bounds;
      if (!bounds.isClosed2D()) {
         bounds = this.computed_bounds;
         if (!bounds.isClosed2D())
            return;
      }
      if (bounds instanceof BoundingCircle) {
         let node = document.createElementNS("http://www.w3.org/2000/svg", "circle");
         node.source_data = this;
         node.setAttribute("cx", bounds.center.x);
         node.setAttribute("cy", bounds.center.y);
         node.setAttribute("r",  bounds.radius);
         node.setAttribute("data-name", this.name);
         return node;
      }
      let node = document.createElementNS("http://www.w3.org/2000/svg", "rect");
      node.source_data = this;
      node.style.setProperty("--x-min", bounds.min.x);
      node.style.setProperty("--y-min", bounds.min.y);
      node.style.setProperty("--x-max", bounds.max.x);
      node.style.setProperty("--y-max", bounds.max.y);
      node.setAttribute("data-name", this.name);
      return node;
   }
};

export class GroupCollection {
   constructor() {
      this.groups = {
         tree:          [], // earliest = highest-priority
         flat_exterior: [], // exterior groups only
      };
   }
   
   load_from_payload(root) {
      let pending = [];
      root.querySelectorAll("quest").forEach((node) => {
         node.querySelectorAll(":scope>:is(top-g, g)").forEach((g_node) => {
            let g = Group.from_node(g_node);
            pending.push(g);
            this.groups.tree.push(g);
         });
      });
      
      const self = this;
      function walk(g, parent, exterior) {
         let parent_exterior = exterior;
         if (exterior !== false) {
            if (g.conditions.confirmed_interior) {
               exterior = false;
            } else if (g.conditions.confirmed_exterior) {
               exterior = true;
            }
         }
         if (exterior && (g.lines.length || g.invokes)) {
            let store = true;
            if (parent_exterior) {
               //
               // Don't store a group if it has the exact same bounds as its parent.
               //
               store = !g.computed_bounds.equals(parent.computed_bounds);
            }
            if (store)
               self.groups.flat_exterior.push(g);
         }
         
         for(let child of g.children) {
            walk(child, g, exterior);
         }
      }
      for(let g of pending) {
         walk(g);
      }
   }
};