Scriptname AskWherePeopleAreFRAGMENTBribe extends TopicInfo Hidden

FavorDialogueScript Property pFDS Auto  

Function Exec(ObjectReference akSpeaker)
   pFDS.Bribe(akSpeaker as Actor)
EndFunction
