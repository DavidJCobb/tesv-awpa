
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
}

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

function awpa.env:lookup_actor(needle)
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
         ["InvisibleInfo"] = { "" },
         ["BeginActorSelection"] = {
            "Who are you looking for?",
            "Who is it? I might have seen them around.",
         },
         ["CancelActorSelection"] = {
            "Suit yourself.",
            "All right, then.",
         },
         ["ActorSelected"] = { "" },
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

   for i = 1, #self.quests do
      local quest = self.quests[i]
      quest:generate_dialogue()
   end
end