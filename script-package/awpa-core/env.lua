
if not awpa then
   awpa = {}
end

awpa.env = {
   elements_by_id     = {},
   quests             = {},
   shared_infos       = {},
   shared_infos_by_id = {},
   
   shared_info_quest = nil,
   shared_info_topic = nil,
   
   built_in_shared_infos = {},
   
   diagnose_topic_helper_deletions = false,
   
   content_counts = {
      extant    = 0,
      generated = 0,
      on_change = nil,
   }
}

function awpa.env:reset()
   self.elements_by_id     = {}
   self.quests             = {}
   self.shared_infos       = {}
   self.shared_infos_by_id = {}
   
   self.shared_info_quest = nil
   self.shared_info_topic = nil
   
   self.built_in_shared_infos = {}
   
   self.diagnose_topic_helper_deletions = false
   
   self.content_counts.extant    = 0
   self.content_counts.generated = 0
end

function awpa.env:on_content_object_constructed()
   self.content_counts.extant = self.content_counts.extant + 1
end
function awpa.env:on_content_object_processed()
   local cc <const> = self.content_counts
   cc.generated = cc.generated + 1
   
   local callback = cc.on_change
   if callback then
      callback(cc.extant, cc.generated)
   end
end

function awpa.env:set_object_id(object, id)
   local is_shared_info = awpa.shared_info_set.is(object)
   if object.id then
      self.elements_by_id[object.id] = nil
      if is_shared_info then
         self.shared_infos_by_id[object.id] = nil
      end
   end
   if not id then
      return
   end
   local prior = self.elements_by_id[id]
   if prior then
      error("ID " .. tostring(id) .. " is already in use!")
   end
   object.id = id
   self.elements_by_id[id] = object
   if is_shared_info then
      self.shared_infos_by_id[id] = object
   end
end

function awpa.env:lookup_quest(needle)
   local list = self.quests
   local size = #list
   if object_is_form(needle) then
      if needle.form_type ~= form_types.quest then
         return nil
      end
      for i = 1, size do
         local item = list[i]
         if item.form == needle then
            return item
         end
      end
      return nil
   end
   for i = 1, size do
      local item = list[i]
      if item.id == needle then
         return item
      end
   end
end

function awpa.env:lookup_object_by_path(path)
   local path_size = #path
   local item
   local i
   do
      if path:sub(1, 2) ~= '#' then
         return nil
      end
      local id
      local k  = path:find("/")
      if k then
         id = path:sub(2, k)
         i  = k + 1
      else
         id = path:sub(2)
         i  = path_size
      end
      item = self.elements_by_id[id]
   end
   while item and i < path_size do
      local segm
      local k = path:find("/", i)
      if k then
         segm = path:sub(i, k)
         i    = k + 1
      else
         segm = path:sub(i)
         i    = path_size
      end
      if not segm then
         return nil
      end
      
      if segm:sub(1, 2) == '@' then
         segm = tonumber(segm:sub(2))
         if not segm then
            return nil
         end
         item = item.groups[segm]
      else
         local found
         for k = 1, #item.groups do
            if item.groups[k].name == segm then
               found = item.groups[k]
               break
            end
         end
         if found then
            item = found
         else
            return nil
         end
      end
   end
   return item
end

function awpa.env:replace_topic_infos_with_builtin_shared_infos(topic, key, options)
   --
   -- NOTE: Currently, built-in shared infos are never gendered, and we have no 
   --       code to generate gendered ones. Therefore this function doesn't try 
   --       to handle gendering, GetIsSex checks, et cetera.
   --

   local infos
   if options and options.prior_infos then
      infos = options.prior_infos
   else
      infos = topic.infos
   end
   
   local unused   = {}
   local recycled = {}
   local src      = self.built_in_shared_infos[key]
   if not src then
      error("Invalid shared-info key")
   end
   local src_count = #src
   --
   -- Find pre-existing infos to recycle (i.e. pre-existing infos that already 
   -- use our shared infos), and track pre-existing infos that don't correspond 
   -- to our shared infos.
   --
   for i = 1, #infos do
      local info = infos[i]
      local si   = info.use_shared_info
      if si then
         for j = 1, src_count do
            if si == src[j] then
               recycled[j] = info
               goto found
            end
         end
      end
      ::not_found::
      unused[#unused + 1] = info
      ::found::
   end
   --
   -- Generate a list of all recycled or created infos.
   --
   local desired_order = {}
   do
      local process_si
      if options then
         process_si = options.process_shared
      end
      for i = 1, src_count do
         local info = recycled[i]
         if not info then
            info = dovah.create_form(form_types.topic_info, { parent = topic })
            info.use_shared_info = src[i]
            utils.clear_info_responses(info)
         end
         desired_order[i] = info
         if src_count > 1 then
            info.is_random = true
            if i == src_count then
               info.is_random_end = true
            end
         end
         if process_si then
            process_si(info)
         end
      end
      --
      -- Delete any pre-existing infos that we did not recycle, and that the caller 
      -- does not wish to retain.
      --
      if options and options.process_unused then
         local functor = options.process_unused
         local j       = #desired_order + 1
         for i = 1, #unused do
            local info = unused[i]
            if functor(info) then
               desired_order[j] = info
               j = j + 1
            else
               info:delete()
            end
         end
      else
         --
         -- Delete any pre-existing infos that we did not recycle.
         --
         for i = 1, #unused do
            unused[i]:delete()
         end
      end
   end
   --
   -- Enforce desired ordering for all infos remaining in the topic.
   --
   if options and options.reorder then
      options.reorder(desired_order)
   end
   do
      local process
      if options then
         process = options.process_all_retained
      end
      for i = 1, #desired_order do
         local info = desired_order[i]
         local prev = desired_order[i - 1]
         topic:place_info_after(info, prev)
         if process then
            process(info, i)
         end
      end
   end
end

function awpa.env:generate_content()
   if not self.shared_info_quest then
      local quest = dovah.get_form_by_editor_id("AWPASharedInfos", form_types.quest)
      if not quest then
         quest = dovah.create_form(form_types.quest)
         quest.editor_id = "AWPASharedInfos"
      end
      self.shared_info_quest = quest
   end
   if not self.shared_info_topic then
      local topics = self.shared_info_quest:get_all_dialogue_topics()
      local size   = #topics
      for i = 1, size do
         local topic = topics[i]
         if topic.subtype == "SharedInfo" then
            self.shared_info_topic = topic
         end
      end
      if not self.shared_info_topic then
         local topic = dovah.create_form(form_types.topic, { parent = self.shared_info_quest })
         topic.subtype = "SharedInfo"
         self.shared_info_topic = topic
      end
   end
   
   local preexisting_infos = self.shared_info_topic.infos
   
   do
      local INFOS = {
         ["InvisibleInfo"] = { "   " },
         ["BeginActorSelection"] = {
            "Who are you looking for?",
            "Who is it? I might have seen them around.",
         },
         ["CancelActorSelection"] = {
            "Suit yourself.",
            "All right, then.",
         },
         ["ActorSelected"] = { "..." },
      }
      local infos = preexisting_infos
      local size  = #infos
      for k, v in pairs(INFOS) do
         local forms = {}
         for i = 1, #v do
            local editor_id = string.format("AWPASharedInfo%s%02d", k, i)
         
            local exists = false
            for j = 1, size do
               local info = infos[j]
               if info.editor_id == editor_id then
                  forms[i] = info
                  info.responses[1].text = v[i]
                  exists = true
                  break
               end
            end
            if not exists then
               local info = dovah.create_form(form_types.topic_info, { parent = self.shared_info_topic })
               info.responses:insert({
                  text = v[i],
               })
               info.editor_id = string.format("AWPASharedInfo%s%02d", k, i)
               forms[i] = info
            end
         end
         self.built_in_shared_infos[k] = forms
      end
   end
   for i = 1, #self.shared_infos do
      local si_def = self.shared_infos[i]
      si_def:find_or_create_forms(self.shared_info_topic, preexisting_infos)
   end

local bench_a = benchmark.new()
   for i = 1, #self.quests do
      local quest = self.quests[i]
      quest:generate_dialogue()
      
local bench = benchmark.new()
      quest:visit_topic_helpers(function(topic_helper)
         topic_helper:finalize_info_order()
      end)
awpa.perflog:log(bench, "Time taken to finalize info order for all topic-helpers in quest %s", quest.id)
      --
      -- These are separate steps to account for the case of a pre-existing info 
      -- being moved across topics, such that it is unused in an earlier-processed 
      -- topic but gets used in a later-processed topic.
      --
bench = benchmark.new()
      quest:visit_topic_helpers(function(topic_helper)
         topic_helper:finalize_leftover_info_deletion()
      end)
awpa.perflog:log(bench, "Time taken to finalize leftover info deletion for all topic-helpers in quest %s", quest.id)
   end
end