Scriptname AskWherePeopleAreCoreService extends Quest Hidden

FormList Property AskWherePeopleAreContentQuests Auto
Actor Property PlayerRef Auto

AskWherePeopleAreContentQuestBase _current_location_quest
Bool _do_init_on_update = False

Event OnInit()
   _do_init_on_update = True
   RegisterForSingleUpdate(1.0)
EndEvent

Event OnUpdate()
   If _do_init_on_update
      _do_init_on_update = False
      ;/
         OnInit, we want to start the quest for whatever location the player is 
         in, so that if the user installs the mod mid-playthrough or COCs from 
         the main menu to a relevant location, they can immediately ask where 
         people are. However, doing this in OnInit doesn't work for COCing from 
         the main menu. I don't know why offhand; maybe the per-location quests 
         aren't initialized yet, or maybe the player's current Location isn't 
         being tracked yet.
         
         In any case, using OnUpdate to carry out a brief delay, and doing this 
         post-init, should work.
      /;
      Self.OnPlayerLocationChange(PlayerRef.GetCurrentLocation())
   EndIf
EndEvent

; Called by our player alias.
Function OnPlayerLocationChange(Location akCurrentLocation)
   Int iSize    = AskWherePeopleAreContentQuests.GetSize()
   Int iCurrent = 0
   If !akCurrentLocation
      If !_current_location_quest
         Return
      EndIf
      While iCurrent < iSize
         Quest kCurrent = AskWherePeopleAreContentQuests.GetAt(iCurrent) as Quest
         If kCurrent
            kCurrent.Stop()
         EndIf
         iCurrent = iCurrent + 1
      EndWhile
      _current_location_quest = None
      Return
   EndIf
   
   AskWherePeopleAreContentQuestBase kQuestToStart
   AskWherePeopleAreContentQuestBase kCurrent
   While iCurrent < iSize
      kCurrent = AskWherePeopleAreContentQuests.GetAt(iCurrent) as AskWherePeopleAreContentQuestBase
      If kCurrent
         If akCurrentLocation && kCurrent.pkLocations.Find(akCurrentLocation) >= 0
            kQuestToStart = kCurrent
         Else
            kCurrent.Stop()
         EndIf
      EndIf
      iCurrent = iCurrent + 1
   EndWhile
   _current_location_quest = None
   If kQuestToStart
      kQuestToStart.Start()
      _current_location_quest = kQuestToStart
   EndIf
EndFunction

Function OnPlayerLoadGame()
   If _do_init_on_update
      Return
   EndIf
   Self.OnPlayerLocationChange(PlayerRef.GetCurrentLocation())
EndFunction
