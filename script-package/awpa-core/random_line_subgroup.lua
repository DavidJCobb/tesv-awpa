
if not awpa then
   error("incorrect file order")
end

do
   local instance_members = {}
   awpa.random_line_subgroup = make_class({
      constructor = function(self)
         self.conditions = {}
         self.children   = {} -- vector<variant<shared_info_reference, line, random_line_subgroup>>
         self.name         = "" -- for debugging
      end,
      instance_members = instance_members
   })
   do -- member functions
      --[[--
         
         Returns a table:
         
            {
               male   = {}, -- vector<topic_info>
               female = {}, -- vector<topic_info>
               unisex = {}, -- vector<topic_info>
            }
         
      --]]--
      function instance_members:generate(topic, conditions, conditions_are_sexed)
         local results <const> = awpa.line_collection()
         
         local inner_conditions = {}
         do
            local j = #conditions
            for i = 1, j do
               local item = conditions[i]
               if awpa.condition.is(item) then
                  item = item:to_native_compatible_table()
               end
               inner_conditions[i] = item
            end
            for i = 1, #self.conditions do
               local item = self.conditions[i]
               if awpa.condition.is(item) then
                  item = item:to_native_compatible_table()
               end
               if (not conditions_are_sexed) and item.function_name == "GetIsSex" then
                  conditions_are_sexed = true
               end
               inner_conditions[j + i] = item
            end
            cndlib.strip_redundant_conditions(inner_conditions)
         end
         
         for i = 1, #self.children do
            local item = self.children[i]
            if awpa.line.is(item) then
               results:generate_line(item, topic, inner_conditions, true, conditions_are_sexed)
            elseif awpa.shared_info_reference.is(item) then
               results:generate_shared_info(item, topic, inner_conditions, true, conditions_are_sexed)
            elseif awpa.random_line_subgroup.is(item) then
               results:absorb(item:generate(topic, inner_conditions, conditions_are_sexed))
            else
               error("unexpected object")
            end
         end
         
         return results
      end
   end
end