
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