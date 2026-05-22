
import svg_viewbox_rect from "./svg_viewbox_rect.js";

const CELL_SIZE_WU = 4096;

function _v_flip_rect(rect) {
   let top    = rect.top;
   let bottom = rect.bottom;
   let height = rect.height;
   rect.y      = bottom;
   rect.height = -height;
}

function _deconstruct(svg) {
   let disp_rect = svg.getBoundingClientRect();
   let real_rect = svg_viewbox_rect(svg);
   _v_flip_rect(real_rect);
   let x_scale = disp_rect.width  / real_rect.width;
   let y_scale = disp_rect.height / real_rect.height;
   return [disp_rect, real_rect, x_scale, y_scale];
}

export function pixels_to_world_units(x, y, svg, viewport_relative) {
   let [disp_rect, real_rect, x_scale, y_scale] = _deconstruct(svg);
   if (viewport_relative) {
      x -= disp_rect.left;
      y -= disp_rect.top;
   }
   x = x / x_scale + real_rect.x;
   y = y / y_scale + real_rect.y;
   //y = -y;
   return [x, y];
}
export function world_units_to_pixels(x, y, svg, viewport_relative) {
   let [disp_rect, real_rect, x_scale, y_scale] = _deconstruct(svg);
   //y = -y;
   x = (x - real_rect.x) * x_scale;
   y = (y - real_rect.y) * y_scale;
   if (viewport_relative) {
      x += disp_rect.left;
      y += disp_rect.top;
   }
   return [x, y];
}
export function pixels_to_grid_units(x, y, svg, viewport_relative) {
   let wu = pixels_to_world_units(x, y, svg, viewport_relative);
   return world_units_to_grid_units(wu[0], wu[1]);
}
export function grid_units_to_pixels(x, y, svg, viewport_relative) {
   x *= CELL_SIZE_WU;
   y *= CELL_SIZE_WU;
   return this.world_units_to_pixels(x, y, svg, viewport_relative);
}

export function world_units_to_grid_units(x, y) {
   let grid_x = Math.floor(x);
   let grid_y = Math.floor(y);
   grid_x /= CELL_SIZE_WU;
   grid_y /= CELL_SIZE_WU;
   grid_x = Math.floor(grid_x);
   //grid_y = Math.ceil(grid_y);
   grid_y = Math.floor(grid_y);
   return [grid_x, grid_y];
}
