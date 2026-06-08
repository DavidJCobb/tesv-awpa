
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
               --
               -- Caller should've converted the ancestor `conditions` to 
               -- native-compatible tables already.
               --
               inner_conditions[i] = conditions[i]
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
local bench = benchmark.new()
local count = #inner_conditions
            cndlib.strip_redundant_conditions(inner_conditions)
if self.name and self.name ~= "" then
   awpa.perflog:log(bench, "time for a named random-line-subgroup (%s) to strip redundant conditions (%u -> %u conditions)", self.name, count, #inner_conditions)
else
   awpa.perflog:log(bench, "time for an unnamed random-line-subgroup to strip redundant conditions (%u -> %u conditions)", count, #inner_conditions)
end
         end
         
local bench = benchmark.new()
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
if self.name and self.name ~= "" then
   awpa.perflog:log(bench, "time for a named random-line-subgroup (%s) to generate its contents (%u children) (sexed conditions: %q)", self.name, #self.children, conditions_are_sexed)
else
   awpa.perflog:log(bench, "time for an unnamed random-line-subgroup to generate its contents (%u children) (sexed conditions: %q)", #self.children, conditions_are_sexed)
end
         
         return results
      end
   end
end