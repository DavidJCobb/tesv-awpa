
export default function svg_viewbox_rect(svg) {
   let view_box = svg.getAttribute("viewBox");
   if (!view_box) {
      let rect = svg.getBoundingClientRect();
      return new DOMRect(0, 0, rect.width, rect.height);
   }
   view_box = view_box.split(" ");
   return new DOMRect(
      +view_box[0],
      +view_box[1],
      +view_box[2],
      +view_box[3]
   );
}
