
if not awpa then
   awpa = {}
end

local VALID_EMOTIONS = {
   "anger",
   "disgust",
   "fear",
   "happy",
   "neutral",
   "puzzled",
   "sad",
   "surprise",
}

do
   local instance_members = {}
   awpa.line = make_class({
      constructor = function(self)
         self.source_xml_node = nil
         
         self.hours_until_reset = 0
         self.script_notes      = ""
         self.text              = ""
         self.vanilla           = nil
         
         self.emotion = {
            type  = "neutral",
            value = 50,
         }
         
         self.form_ids = {
            unisex = nil,
            male   = nil,
            female = nil,
         }
         self.forms = {
            unisex = nil,
            male   = nil,
            female = nil,
         }
         
         self.is_gendered = false
         self.text_fem    = nil
         
         awpa.env:on_content_object_constructed()
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:from_xml(element)
         self.source_xml_node = element
         
         local hours = tonumber(element.attributes["hours-until-reset"])
         if hours then
            self.hours_until_reset = hours
            if hours < 0 or hours > 24 then
               error("invalid value for `hours-until-reset` (must be in the range [0, 24])")
            end
         elseif element.attributes["hours-until-reset"] then
            error("invalid value for `hours-until-reset` (not a number)")
         end
         
         local notes = element.attributes["script-notes"]
         if notes then
            self.script_notes = notes
         end
         
         local vanilla = element.attributes["vanilla"]
         if vanilla then
            -- TODO: parse form reference
         else
            vanilla = element.attributes["vanilla-fragment"]
            if vanilla then
               -- TODO: parse form reference
            end
         end
         
         do
            local raw = element.attributes["emotion"]
            if raw then
               local t, v = raw:match("^([^:]+):(%d+)$")
               if t then
                  v = tonumber(v)
                  if v < 0 or v > 100 then
                     error("emotion value out of range")
                  end
                  for _, allowed in ipairs(VALID_EMOTIONS) do
                     if t == allowed then
                        goto valid
                     end
                  end
                  error(string.format("unrecognized emotion typename (`%s` in `%s`)", t, raw))
                  ::valid::
                  self.emotion.type  = t
                  self.emotion.value = v
               end
            end
         end
         
         do
            local text_m   = ""
            local text_f   = ""
            local list     = element.children
            local gendered = false
            for i = 1, #list do
               local node = list[i]
               if xml.text.is(node) then
                  local data <const> = node.data
                  text_m = text_m .. data
                  if not gendered then
                     gendered = has_masc_pronouns(data)
                  end
                  if gendered then
                     text_f = text_f .. swap_masc_pronouns_to_fem(data)
                  else
                     text_f = text_f .. data
                  end
               elseif xml.element.is(node) then
                  if node.node_name == "verbatim" then
                     local data <const> = node:get_text_content()
                     text_m = text_m .. data
                     text_f = text_f .. data
                  else
                     error("unexpected child element in `line`")
                  end
               end
            end
            self.text        = text_m
            self.is_gendered = gendered
            if gendered then
               self.text_fem = text_f
            end
         end
         
         do
            local id = element.attributes["form-id-m"]
            if id then
               id = tonumber(id, 16)
               self.form_ids.male = id
            end
         end
         do
            local id = element.attributes["form-id-f"]
            if id then
               id = tonumber(id, 16)
               self.form_ids.female = id
            end
         end
         do
            local id = element.attributes["form-id-u"]
            if id then
               id = tonumber(id, 16)
               self.form_ids.unisex = id
            end
         end
      end
      function instance_members:amend_xml_clone(nodemap)
         local node = nodemap[self.source_xml_node]
         if (self.hours_until_reset or 0) > 0 then
            node.attributes["hours-until-reset"] = self.hours_until_reset
         else
            node.attributes["hours-until-reset"] = nil
         end
         if self.script_notes and self.script_notes ~= "" then
            node.attributes["script-notes"] = self.script_notes
         else
            node.attributes["script-notes"] = nil
         end
         
         -- TODO: `vanilla`
         -- TODO: `vanilla-fragment`
         
         if self.form_ids.male then
            node.attributes["form-id-m"] = string.format("%08X", self.form_ids.male)
         else
            node.attributes["form-id-m"] = nil
         end
         if self.form_ids.female then
            node.attributes["form-id-f"] = string.format("%08X", self.form_ids.female)
         else
            node.attributes["form-id-f"] = nil
         end
         if self.form_ids.unisex then
            node.attributes["form-id-u"] = string.format("%08X", self.form_ids.unisex)
         else
            node.attributes["form-id-u"] = nil
         end
      end
      
      function instance_members:generate_infos(topic)
         local bench_a = benchmark.new()
         
         local bench_b = benchmark.new()
         local gendered = self.is_gendered
         bench_b:stop()
         
         local bench_c
         local bench_d
         
         local target_alias = nil
         if gendered then
            target_alias = topic.parent_quest.aliases["ActorToFind"]
         end
         
         local function _get_or_create_by_id(id)
            if id then
               local info = dovah.get_form_by_id(id)
               if info and info.form_type == form_types.topic_info then
                  info.conditions:clear() -- let group conditions be rebuilt from scratch
                  return info
               end
            end
            return dovah.create_form(form_types.topic_info, { parent = topic })
         end
         local function _configure(info, fem)
            info.hours_until_reset = self.hours_until_reset
            info.use_shared_info   = nil
            info.is_random         = true
            
            if gendered then
               info.conditions:insert({
                  run_on        = target_alias,
                  function_name = "GetIsSex",
                  parameters    = { fem and "Female" or "Male" },
                  comparison    = {
                     operator = "==",
                     operand  = 1
                  }
               })
            end
         
            local resp_list = info.responses
            local text      = self.text
            if fem then
               text = self.text_fem
            end
            resp_list[1] = {
               text          = text,
               script_notes  = self.script_notes,
               emotion_type  = self.emotion.type,
               emotion_value = self.emotion.value,
            }
         end
         
         local function _print_benches()
            awpa.perflog:log(bench_a, "awpa.line:generate_infos(...) for text: \"%s\"", self.text)
            awpa.perflog:log(bench_b, " - `has_masc_pronouns` execution time (result: %d)", gendered and 1 or 0)
            if bench_c then
               awpa.perflog:log(bench_c, " - `swap_masc_pronouns_to_fem` execution time")
            end
            if bench_d then
               awpa.perflog:log(bench_d, " - execution time to update progress bar")
            end
         end
         
         bench_d = benchmark.new()
         awpa.env:on_content_object_processed()
         bench_d:stop()
         if gendered then
            local info_m = _get_or_create_by_id(self.form_ids.male)
            local info_f = _get_or_create_by_id(self.form_ids.female)
            self.form_ids.unisex = nil
            self.form_ids.male   = info_m.form_id
            self.form_ids.female = info_f.form_id
            _configure(info_m, false)
            _configure(info_f, true)
            _print_benches()
            return info_m, info_f
         else
            local info_u = _get_or_create_by_id(self.form_ids.unisex)
            self.form_ids.unisex = info_u.form_id
            self.form_ids.male   = nil
            self.form_ids.female = nil
            _configure(info_u, false)
            _print_benches()
            return info_u
         end
      end
   end
end