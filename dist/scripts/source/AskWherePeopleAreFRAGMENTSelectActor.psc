Scriptname AskWherePeopleAreFRAGMENTSelectActor extends TopicInfo Hidden

ReferenceAlias Property pkSrcAlias Auto
ReferenceAlias Property pkDstAlias Auto

Function Exec(ObjectReference akSpeaker)
   pkDstAlias.ForceRefTo(pkSrcAlias.GetReference())
EndFunction
