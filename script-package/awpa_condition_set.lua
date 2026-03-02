
if not awpa then
   awpa = {}
end

do
   local instance_members = {}
   awpa.condition_set = make_class({
      constructor = function(self)
         self.source_xml_node = nil
         
         self.name         = nil
         self.conditions   = {}
         self.owning_scope = nil
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:from_xml(element)
         self.source_xml_node = element
      
         local n = element.attributes["name"]
         if n then
            self.name = n
         else
            error("condition set definition has no name")
         end
      end
      function instance_members:apply_to(group, node)
         local attr_of = node.attributes["of"]
      
         local dst_i = #group.conditions + 1
         for src_i = 1, #self.conditions do
            local cnd = self.conditions[src_i]:copy()
            if attr_of then
               cnd:_extract_run_on(node)
            end
            group.conditions[dst_i] = cnd
            dst_i = dst_i + 1
         end
      end
   end
end