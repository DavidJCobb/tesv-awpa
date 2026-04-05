
MTF_PRONOUNS = {
   ["he"]      = "she",
   ["him"]     = "her",
   ["his"]     = "her",
   ["himself"] = "herself",
}

local pronoun_test_patterns = {}
do
   local i = 1
   for k, v in pairs(MTF_PRONOUNS) do
      local pattern = k:sub(1, 1)
      pattern = "[" .. pattern:upper() .. pattern:lower() .. "]"
      pattern = "%f[%w_]" .. pattern .. k:sub(2) .. "%f[^%w_]"
      pronoun_test_patterns[i] = pattern
      i = i + 1
   end
end

local pronoun_swap_patterns = {}
do
   local i = 1
   for k, v in pairs(MTF_PRONOUNS) do
      local needle
      local wanted
      
      -- lowercase first
      needle = "%f[%w_]" .. k .. "%f[^%w_]"
      wanted = v
      pronoun_swap_patterns[i] = { needle, wanted }
      i = i + 1
      
      -- capitalized next
      k = k:sub(1, 1):upper() .. k:sub(2)
      v = v:sub(1, 1):upper() .. v:sub(2)
      --
      needle = "%f[%w_]" .. k .. "%f[^%w_]"
      wanted = v
      pronoun_swap_patterns[i] = { needle, wanted }
      i = i + 1
   end
end

function has_masc_pronouns(text)
   for i = 1, #pronoun_test_patterns do
      if text:find(pronoun_test_patterns[i]) then
         return true
      end
   end
   return false
end

local FEM_PRONOUNS_UPPERCASE = {}
do
   for _, v in pairs(MTF_PRONOUNS) do
      local capped = v:sub(1, 1):upper() .. v:sub(2)
      FEM_PRONOUNS_UPPERCASE[v] = capped
   end
end

function swap_masc_pronouns_to_fem(text)
   --[[--
   for i = 1, #pronoun_swap_patterns do
      local pair = pronoun_swap_patterns[i]
      local src  = pair[1]
      local dst  = pair[2]
      text = text:gsub(src, dst)
   end
   return text
   --]]--
   
   -- better performance:
   local i    = text:find("[Hh]")
   local size = #text
   while i and i < size do
      if i > 1 and not text:sub(i - 1, i - 1):match("[^%w_]") then
         -- not the start of a new word
         goto continue
      end
      for k, v in pairs(MTF_PRONOUNS) do
         local kl = #k
         if text:sub(i + kl, i + kl):match("[^%w_]") then -- word separator?
            if text:sub(i, i + kl - 1):lower() == k then
               local repl = v
               if text:sub(i, i) == 'H' then
                  repl = FEM_PRONOUNS_UPPERCASE[v]
               end
               text = text:sub(1, i - 1) .. repl .. text:sub(i + kl)
               size = #text
               break
            end
         end
      end
      ::continue::
      i = text:find("[Hh]", i + 1)
   end
   return text
end
