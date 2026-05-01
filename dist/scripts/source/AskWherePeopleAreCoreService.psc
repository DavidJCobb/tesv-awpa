Scriptname AskWherePeopleAreCoreService extends Quest Hidden

FormList Property AskWherePeopleAreContentQuests Auto
Actor Property PlayerRef Auto

Event OnInit()
   Location kLoc = PlayerRef.GetCurrentLocation()
   If kLoc
      Self.OnPlayerLocationChange(None, kLoc)
   EndIf
EndEvent

; Called by our player alias.
Function OnPlayerLocationChange(Location akPrior, Location akAfter)
   Int iSize    = AskWherePeopleAreContentQuests.GetSize()
   Int iCurrent = 0
   
   AskWherePeopleAreContentQuestBase kQuestToStop
   AskWherePeopleAreContentQuestBase kQuestToStart
   AskWherePeopleAreContentQuestBase kCurrent
   While iCurrent < iSize
      kCurrent = AskWherePeopleAreContentQuests.GetAt(iCurrent) as AskWherePeopleAreContentQuestBase
      If kCurrent
         If akPrior && kCurrent.IsRunning() && kCurrent.pkLocations.Find(akPrior) >= 0
            kQuestToStop = kCurrent
         EndIf
         If akAfter && kCurrent.pkLocations.Find(akAfter) >= 0
            kQuestToStart = kCurrent
         EndIf
      EndIf
      iCurrent = iCurrent + 1
   EndWhile
   If kQuestToStop == kQuestToStart
      ;
      ; This quest applies to multiple Locations, and the player has 
      ; merely moved between them.
      ;
      Return
   EndIf
   If kQuestToStop
      kQuestToStop.Stop()
   EndIf
   If kQuestToStart
      kQuestToStart.Start()
   EndIf
EndFunction
