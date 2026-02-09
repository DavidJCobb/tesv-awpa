
if not awpa then
   awpa = {}
end

do
   local instance_members = {}
   awpa.actor = make_class({
      constructor = function(self)
         self.editor_id = nil
         self.name      = nil
         self.form      = nil
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:from_xml(element)
         self.editor_id = element.attributes["editor-id"]
         self.name      = element.attributes["name"]
         if not self.name then
            self.name = self.editor_id
         end
         if not self.editor_id then
            error("Actor is missing an editor ID")
         end
         self.form = dovah.get_form_by_editor_id(self.editor_id, form_types.actor_base)
      end
   end
end