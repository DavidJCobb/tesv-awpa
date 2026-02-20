
do
   local instance_members = {}
   awpa.actor = make_class({
      constructor = function(self)
         self.editor_id = nil
         self.name      = nil
         self.form      = nil
         self.overrides = {
            begin_asking_about = {
               --
               -- Override whether other actors can be asked about this actor.
               --
               conditions = {},
            },
            begin_asking_to = {
               --
               -- Override this actor's responses to "Can you help me find someone?"
               --
               conditions = {},
               bribe      = nil, -- optional<awpa.actor_override_bribe>
               results    = {},  -- vector<variant<awpa.group, awpa.line>>
            },
            begin_responding = {
               --
               -- Override this actor's responses to inquiries about any other actor.
               --
               conditions = {},
               results    = {}, -- vector<variant<awpa.group, awpa.line>>
            },
         }
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