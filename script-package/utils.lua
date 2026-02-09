
utils = {}
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
      GLOB = form_types.global,
      REFR = form_types.reference,
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