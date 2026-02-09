
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

function swap_masc_pronouns_to_fem(text)
   for i = 1, #pronoun_swap_patterns do
      local pair = pronoun_swap_patterns[i]
      local src  = pair[1]
      local dst  = pair[2]
      text = text:gsub(src, dst)
   end
   return text
end
