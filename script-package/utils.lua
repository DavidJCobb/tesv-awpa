
utils = {}

function utils.get_or_create_branch(quest, editor_id, prior_branches)
   if not prior_branches then
      prior_branches = quest:get_all_dialogue_branches()
   end
   for i = 1, #prior_branches do
      local branch = prior_branches[i]
      if branch.editor_id == editor_id then
         return branch, prior_branches
      end
   end
   local branch = dovah.create_form(form_types.dialogue_branch, { parent = quest })
   branch.editor_id = editor_id
   branch.type      = "normal"
   return branch, prior_branches
end

function utils.get_or_create_topic(branch, editor_id, prior_topics)
   if not prior_topics then
      prior_topics = branch:get_all_topics()
   end
   for i = 1, #prior_topics do
      local topic = prior_topics[i]
      if topic.editor_id == editor_id then
         return topic, prior_topics
      end
   end
   local topic = dovah.create_form(form_types.topic, { parent = branch })
   topic.editor_id = editor_id
   return topic, prior_topics
end

--

function utils.clear_info_responses(info)
   local list = info.responses
   local size = #list
   for i = size, 1, -1 do
      list:remove(i)
   end
end

function utils.make_invisible_info(topic, editor_id, destination)
   local infos = topic.infos
   local info
   for i = 1, #infos do
      local item = infos[i]
      if item.editor_id == editor_id then
         info = item
         break
      end
   end
   if not info then
      info = dovah.create_form(form_types.topic_info, { parent = topic })
      info.editor_id = editor_id
   end
   
   info.use_shared_info = awpa.env.built_in_shared_infos["InvisibleInfo"][1]
   
   if type(destination) == "userdata" then
      destination = { destination }
   end
   utils.replace_info_link_to_list(info, destination)
   
   return info
end

function utils.replace_condition_list(info, conditions)
   local list = info.conditions
   for i = #list, 1, -1 do
      list:remove(i)
   end
   utils.append_condition_list(info, conditions)
end
function utils.append_condition_list(info, src_list)
   local dst_list = info.conditions
   if src_list and src_list.function_name then
      src_list = { src_list }
   end
   for i = 1, #src_list do
      local src = src_list[i]
      if awpa.condition.is(src) then
         src:apply_to_info(info)
         goto continue
      end
      local dst = dst_list:insert()
      dst.run_on        = src.run_on
      dst.function_name = src.function_name
      if src.parameters then
         for j = 1, 2 do
            dst.parameters[j] = src.parameters[j]
         end
      else
         for j = 1, 2 do
            dst.parameters[j] = nil
         end
      end
      dst.comparison.operator = src.comparison.operator
      dst.comparison.operand  = src.comparison.operand
      ::continue::
   end
end

function utils.replace_info_link_to_list(info, topics)
   local list = info.link_to
   local size = #list
   if size > 0 then
      for i = size, 1, -1 do
         list:remove(i)
      end
   end
   size = #topics
   for i = 1, size do
      list:insert(topics[i])
   end
end

function utils.replace_info_responses(info, text)
   local size = #info.responses
   if size <= 0 then
      info.responses:insert({ text = text })
   else
      info.responses[1].text = text
      for i = 2, size do
         info.responses:remove(i)
      end
   end
end

function utils.resolve_form_reference(text)
   local SIGS = {
      ACHR = form_types.actor,
      ACTI = form_types.activator,
      ALCH = form_types.potion,
      AMMO = form_types.ammo,
      ARMO = form_types.armor,
      BOOK = form_types.book,
      FURN = form_types.furniture,
      GLOB = form_types.global,
      KEYM = form_types.key,
      MISC = form_types.misc_item,
      MSTT = form_types.movable_static,
      NPC_ = form_types.actor_base,
      QUST = form_types.quest,
      REFR = form_types.reference,
      SCRL = form_types.scroll,
      SLGM = form_types.soul_gem,
      STAT = form_types.static,
      WEAP = form_types.weapon,
   }
   
   local sig, form_id, editor_id = text:match("^%[(....):(%x%x%x%x%x%x%x%x)%](.*)$")
   if not form_id then
      sig, editor_id = text:match("^%[(....)%](.*)$")
      if not sig then
         error("malformed form reference: " .. text)
      end
   end
   
   local ft = SIGS[sig]
   if not ft then
      error("bad form-reference signature: " .. sig)
   end
   
   local form
   if form_id then
      form_id = tonumber(form_id, 16)
      form    = dovah.get_form_by_id(form_id)
   else
      form = dovah.get_form_by_editor_id(editor_id, ft)
   end
   
   if not form then
      error(string.format(
         "form not found: %s",
         text
      ))
   end
   if form_id then
      if form.form_type ~= ft then
         error(string.format(
            "form is of the wrong type: %X (expected %s)",
            form_id,
            sig
         ))
      end
      if editor_id and form.editor_id ~= editor_id then
         error(string.format(
            "form has the wrong editor ID: %X (expected '%s'; saw '%s')",
            form_id,
            editor_id,
            form.editor_id
         ))
      end
   end
   return form
end