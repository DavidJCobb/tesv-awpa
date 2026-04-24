
do
   local instance_members = {}
   awpa.actor_redirect_topic = make_class({
      superclass  = awpa.actor_redirect,
      constructor = function(
         self,
         actor_info,
         
         -- Format string. Params:
         --  - quest editor ID
         --  - actor editor ID
         --  - slug, if specified
         topic_editor_id_format,
         
         -- Format string. Params:
         --  - quest editor ID
         --  - actor editor ID
         --  - slug, if specified
         link_info_editor_id_format
      )
         self.forms.topic = nil
         
         self.slug     = ""
         self.children = {} -- vector<variant<awpa.line, awpa.group, awpa.shared_info_reference>>
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:visit_topic_helpers(visitor)
         -- no-op.
      end
      
      function instance_members:from_xml(element)
         if element.attributes["slug"] then
            self.slug = element.attributes["slug"]
         end
         
         element:for_each_child_element(function(node)
            if node.node_name == "conditions" then
               awpa.condition.construct_list_from_xml(node, self.conditions, {
                  scope      = self.quest_info,
                  quest_info = self.quest_info,
               })
               return
            end
            if node.node_name == "g" then
               local item = awpa.group(self.quest_info)
               local list = self.children
               list[#list + 1] = item
               item.parent = self
               item:from_xml(node)
               return
            end
            if node.node_name == "line" then
               local item = awpa.line()
               local list = self.children
               list[#list + 1] = item
               item:from_xml(node)
               return
            end
            if node.node_name == "shared-info" then
               local item = awpa.shared_info_reference()
               local list = self.children
               list[#list + 1] = item
               item:from_xml(node)
               return
            end
            error("unexpected element: " .. node.node_name)
         end)
      end
      function instance_members:amend_xml_clone(nodemap)
         for i = 1, #self.children do
            self.children[i]:amend_xml_clone(nodemap)
         end
      end
      
      function instance_members:fold()
         local actor_condition <const> = {
            run_on        = "subject",
            function_name = "GetIsId",
            parameters    = { self.actor_info.form },
            comparison    = {
               operator = "==",
               operand  = 1,
            }
         }
      
         local dst_list = awpa.random_line_group.fold(self)
         for i = 1, #dst_list do
            local dst_item = dst_list[i]
            if awpa.random_line_group.is(dst_item) then
               local cnd_list = {}
               cnd_list[1] = actor_condition
               utils.join(cnd_list, self.conditions)
               utils.join(cnd_list, dst_item.conditions)
               dst_item.conditions = cnd_list
            end
         end
         return dst_list
      end
   end
end