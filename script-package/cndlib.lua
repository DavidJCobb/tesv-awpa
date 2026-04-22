cndlib = {}

function cndlib.extract_comparison_to_table(cnd)
   local cmp = cnd.comparison
   return {
      operator = cmp.operator,
      operand  = cmp.operand
   }
end
function cndlib.extract_condition_to_table(cnd)
   local parameters = cnd.parameters
   return {
      run_on        = cnd.run_on,
      function_name = cnd.function_name,
      parameters    = { parameters[1], parameters[2] },
      comparison    = cndlib.extract_comparison_to_table(cnd),
      is_or_linked  = cnd.is_or_linked,
      
      override_types_with     = cnd.override_types_with,
      swap_subject_and_target = cnd.swap_subject_and_target,
   }
end

-- Returns `true` if the comparison checks if a condition is true.
-- Returns `false` if the comparison checks if a condition is false.
-- Returns `nil` if the comparison is not a well-formed boolean check.
function cndlib.boolean_comparison_is_truthy(cmp)
   local op = cmp.operator
   if op == "==" then
      return cmp.operand == 1
   end
   if op == "!=" then
      return cmp.operand == 0
   end
   if op == ">"  and cmp.operand == 0 then
      return true
   end
   if op == ">=" and cmp.operand == 1 then
      return true
   end
   if op == "<"  and cmp.operand == 1 then
      return false
   end
   if op == "<=" and cmp.operand == 0 then
      return false
   end
end

-- Returns `false` if no overlap. Otherwise, returns an integer:
--    -1: `a` is more specific and should be retained
--     0: conditions are equal
--     1: `b` is more specific and should be retained
function cndlib.numeric_comparisons_are_redundant(cmp_a, cmp_b)
   if cmp_a.operator == cmp_b.operator then -- same operator
      if cmp_a.operand == cmp_b.operand then
         return 0
      end
      local op = cmp_a.operator
      if op == "==" or op == "!=" then
         return false
      end
      if op == "<" or op == "<=" then
         if cmp_a.operand < cmp_b.operand then
            return -1
         end
         return 1
      end
      if op == ">" or op == ">=" then
         if cmp_a.operand > cmp_b.operand then
            return -1
         end
         return 1
      end
      return false
   end
   do -- operator == is more specific than >= and <=
      local a_eq = cmp_a.operator == "=="
      local b_eq = cmp_b.operator == "=="
      if a_eq or b_eq then
         local cmp_equal = cmp_a
         local cmp_other = cmp_b
         if b_eq then
            cmp_equal, cmp_other = cmp_b, cmp_a
         end
         
         if cmp_other.operator == "<=" and cmp_equal.operand <= cmp_other.operand
         or cmp_other.operator == ">=" and cmp_equal.operand >= cmp_other.operand
         then
            return a_eq and -1 or 1
         end
      end
   end
   return false
end

-- Returns -1 if A overlaps B and A is more specific.
-- Returns  0 if A and B are exactly equal.
-- Returns  1 if A overlaps B and B is more specific.
-- Returns false if no overlap.
do
   local BOOLEAN_FUNCTION_ARGCOUNTS = {
      ["GetDisabled"]          = 0,
      ["GetInCell"]            = 1,
      ["GetInCurrentLoc"]      = 1,
      ["GetInFaction"]         = 1,
      ["GetInWorld"]           = 1,
      ["GetIsID"]              = 1,
      ["GetIsRace"]            = 1,
      ["GetIsSex"]             = 1,
      ["GetOffersServicesNow"] = 0,
   }
   
   local NUMERIC_FUNCTION_ARGCOUNTS = {
      ["GetDeadCount"]       = 1,
      ["GetDistance"]        = 1,
      ["GetGlobalValue"]     = 1,
      ["GetPos"]             = 1,
      ["GetVMQuestVariable"] = 2,
   }
   
   -- Conditions for which the "run on" ref is completely irrelevant.
   local RUN_ON_IRRELEVANT_CONDITIONS = {
      ["GetDeadCount"]       = true,
      ["GetGlobalValue"]     = true,
      ["GetVMQuestVariable"] = true,
   }

   function cndlib.condition_is_superset(cnd_a, cnd_b)
      local RETAIN_A              = -1
      local RETAIN_EITHER <const> =  0
      local RETAIN_B              =  1
      local NO_REDUNDANCY <const> =  false

      local func_a
      local func_b = cnd_b.function_name
      if not RUN_ON_IRRELEVANT_CONDITIONS[func_b] then
         if cnd_a.run_on ~= cnd_b.run_on then
            return false
         end
      end
      if func_b == "IsInInterior"
      then
         cnd_a, cnd_b = cnd_b, cnd_a
         func_a = func_b
         func_b = cnd_b.function_name
         
         RETAIN_A, RETAIN_B = RETAIN_B, RETAIN_A
      else
         func_a = cnd_a.function_name
      end
      
      local cmp_a = cndlib.extract_comparison_to_table(cnd_a)
      local cmp_b = cndlib.extract_comparison_to_table(cnd_b)
      
      do -- check boolean conditions for exact matches
         local argcount = BOOLEAN_FUNCTION_ARGCOUNTS[func_a]
         if argcount then
            if func_b ~= func_a then
               return NO_REDUNDANCY
            end
            local a_true = cndlib.boolean_comparison_is_truthy(cmp_a)
            local b_true = cndlib.boolean_comparison_is_truthy(cmp_b)
            if a_true == nil    -- condition is not a well-formed bool
            or b_true == nil    -- condition is not a well-formed bool
            or a_true ~= b_true -- conditions do not check for the same result
            then
               return NO_REDUNDANCY
            end
            if argcount > 0 then -- Compare parameters as relevant
               local pa = cnd_a.parameters
               local pb = cnd_b.parameters
               for i = 1, argcount do
                  if pa[i] ~= pb[i] then
                     return NO_REDUNDANCY
                  end
               end
            end
            return 0
         end
      end
      
      do -- check specificity of numeric comparisons
         local argcount = NUMERIC_FUNCTION_ARGCOUNTS[func_a]
         if argcount then
            if func_b ~= func_a then
               return NO_REDUNDANCY
            end
            if argcount > 0 then -- Compare parameters as relevant
               local pa = cnd_a.parameters
               local pb = cnd_b.parameters
               for i = 1, argcount do
                  if pa[i] ~= pb[i] then
                     return NO_REDUNDANCY
                  end
               end
            end
            return cndlib.numeric_comparisons_are_redundant(cmp_a, cmp_b)
         end
      end
      
      -- GetInSameCell redundancies i.e. A.GetInSameCell(B) == B.GetInSameCell(A)
      if func_a == "GetInSameCell" then
         if func_b ~= func_a then
            return NO_REDUNDANCY
         end
         local a_true = cndlib.boolean_comparison_is_truthy(cmp_a)
         local b_true = cndlib.boolean_comparison_is_truthy(cmp_b)
         if a_true == nil or b_true == nil or a_true ~= b_true then
            -- Ill-formed or contradictory conditions.
            return NO_REDUNDANCY
         end
         
         local a_ref_x = cnd_a.run_on
         local b_ref_x = cnd_b.run_on
         if type(a_ref_x) == "string" or type(b_ref_x) == "string" then
            if a_ref_x ~= b_ref_x then
               return NO_REDUNDANCY
            end
         end
         local a_ref_y = cnd_a.parameters[1]
         local b_ref_y = cnd_b.parameters[1]
         if a_ref_x == b_ref_x and a_ref_y == b_ref_y then
            return RETAIN_EITHER
         end
         if a_ref_x == b_ref_y and a_ref_y == b_ref_x then
            return RETAIN_EITHER
         end
         return NO_REDUNDANCY
      end
      
      -- IsInInterior redundancy with other conditions
      if func_a == "IsInInterior" then
         local a_true = cndlib.boolean_comparison_is_truthy(cmp_a)
         local b_true = cndlib.boolean_comparison_is_truthy(cmp_b)
         if a_true == nil or b_true == nil then
            return NO_REDUNDANCY
         end
         if func_b == "IsInInterior" then
            if a_true == b_true then
               return RETAIN_EITHER -- conditions are equivalent
            end
            return NO_REDUNDANCY
         elseif func_b == "GetInWorld" then
            if a_true ~= b_true then
               return RETAIN_B -- GetInWorld is more specific than IsInInterior
            end
            return NO_REDUNDANCY
         elseif func_b == "GetInCell" then
            if b_true then
               local cell = cnd_b.parameters[1]
               if cell then
                  if cell.parent_world then
                     -- A is checking if we're in an interior
                     -- B is checking if we're in an exterior
                     -- Conflict. Ignore.
                     return NO_REDUNDANCY
                  end
                  -- A is checking if we're in any interior
                  -- B is checking if we're in a specific interior
                  -- Retain B.
                  return RETAIN_B
               end
            end
         end
         return NO_REDUNDANCY
      end
      
      return NO_REDUNDANCY
   end
end

-- Takes a native condition list, e.g. some_topic_info.conditions
function cndlib.strip_redundant_conditions(list)
   local or_groups
   do
      local as_tables = {}
      for i = 1, #list do
         as_tables[i] = cndlib.extract_condition_to_table(list[i])
      end
      or_groups = cndlib.list_to_or_groups(as_tables)
   end
   cndlib.strip_redundant_conditions_from_or_groups(or_groups)
   
   local re_flattened = {}
   for i = 1, #or_groups do
      local group = or_groups[i]
      local size  = #group
      for j = 1, size do
         local item = group[j]
         if j < size then
            item.is_or_linked = true
         end
         re_flattened[#re_flattened + 1] = item
      end
   end
   
   local size_prior <const> = #list
   local size_after <const> = #re_flattened
   if size_prior == size_after then
      return
   end
   
   local size_min = size_prior
   if size_prior > size_after then
      size_min = size_after
   end
   
   for i = 1, size_min do
      local src = re_flattened[i]
      local dst = list[i]
      dst:overwrite_with(src)
   end
   if size_after > size_prior then
      for i = size_prior + 1, size_after do
         local src = re_flattened[i]
         local dst = list:insert()
         dst:overwrite_with(src)
      end
   else
      for i = size_prior, size_after + 1, -1 do
         list:remove(i)
      end
   end
end

function cndlib.stringify(cnd)
   local out = {}
   
   local function _stringify_object(o)
      if type(o) ~= "userdata" then
         return tostring(o)
      end
      if dovah.object_is(o, "quest_ref_alias") then
         return o.name or string.format("Alias#%u", o.id or -1)
      elseif dovah.object_is(o, "form") then
         local s = o.editor_id
         if not s or s == "" then
            s = o:form_id_to_string()
         end
         return s
      end
      return "???"
   end

   local run_on = cnd.run_on
   if type(run_on) == "string" then
      out[1] = run_on
   else
      out[1] = _stringify_object(run_on)
   end
   
   out[2] = '.'
   out[3] = cnd.function_name or "?????"
   out[4] = '('
   out[5] = _stringify_object(cnd.parameters[1])
   out[6] = ", "
   out[7] = _stringify_object(cnd.parameters[2])
   out[8] = ") "
   out[9] = cnd.comparison.operator or "??"
   out[10] = " "
   out[11] = _stringify_object(cnd.comparison.operand)
   out[12] = " "
   if cnd.is_or_linked then
      out[13] = "OR"
   else
      out[13] = "AND"
   end
   
   return table.concat(out)
end

function cndlib.list_to_or_groups(list)
   local or_groups = {}
   do
      local j           = 0
      local last_was_or = false
      for i = 1, #list do
         local cnd = list[i]
         if j == 0 or not last_was_or then
            j = j + 1
         end
         local g = or_groups[j]
         if not g then
            g = {}
            or_groups[j] = g
         end
         g[#g + 1] = cnd
         
         last_was_or = cnd.is_or_linked
      end
   end
   return or_groups
end

function cndlib.strip_redundant_conditions_from_or_groups(or_groups)
   --[[--
   
      NOTE: This currently only looks for cases where a single-condition 
      or-group (i.e. a single AND-linked condition) is redundant with an 
      or-group. So for example:
      
         A && (B || C)
         
         (U && V) || (W && X)
         
      The `A` condition may be pruned, but this implementation cannot 
      check the latter pair of or-groups.
      
   --]]--
   local i = 1
   local size = #or_groups
   while i < size do
      local group_a = or_groups[i]
      if #group_a ~= 1 then
         goto continue_1
      end
      do
         local cnd_a = group_a[1]
         
         local j = i + 1
         while j <= size do
            local group_b = or_groups[j]
            local all_rel = nil
            for k = 1, #group_b do
               local cnd_b = group_b[k]
               local rel   = cndlib.condition_is_superset(cnd_a, cnd_b)
               if all_rel == nil then
                  all_rel = rel
               else
                  if all_rel ~= rel then
                     all_rel = false
                     break
                  end
               end
            end
            if not all_rel then
               goto continue_2
            end
            if all_rel == -1 then
               --
               -- Remove `group_b`.
               --
               table.remove(or_groups, j)
               size = size - 1
               j    = j - 1
               goto continue_2
            elseif all_rel == 1 or all_rel == 0 then
               --
               -- Remove `group_a`.
               --
               table.remove(or_groups, i)
               size = size - 1
               i    = i - 1
               break
            end
            ::continue_2::
            j = j + 1
         end
      end
      ::continue_1::
      i = i + 1
   end
end
