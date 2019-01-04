ON INIT 
{
 SET §player_in_sight 0       // 1 indicates that the NPC currently sees he player.
 SET §reflection_mode 1		// 0 : shut up

 SET §enemy 0                  // defines if the NPC is enemy to the player at the moment
 SET §roti 0                   // for chicken only

 SET £tmp "none"			 // misc reflection management
 SET §dead 0			// Used to know if npc is dead
 SET §sound 0
 SET §sound_amount 4
 SET £misc "Pig_idle"
 SET #TMP ~^RND_6~
 INC #TMP 6
 TIMERmisc_reflection -i 0 ~#TMP~ SENDEVENT MISC_REFLECTION SELF ""
 SET £ouch "Pig_hit3"
 SET £ouch_medium "Pig_hit1"
 SET £ouch_strong "Pig_hit2"
 SET £dying "Pig_die"
 SET §confusability 1           // level of magic needed to confuse this npc


 SETEVENT HEAR OFF

 SETNAME [description_pig]

 PHYSICAL RADIUS 20
 SET_NPC_STAT BACKSTAB 1
 SET_MATERIAL FLESH
 SET_ARMOR_MATERIAL LEATHER
 SET_STEP_MATERIAL Foot_bare
 SET_BLOOD 0.9 0.1 0.1
 SET_NPC_STAT RESISTMAGIC 1
 SET_NPC_STAT RESISTPOISON 1
 SET_NPC_STAT RESISTFIRE 1
 SET_NPC_STAT armor_class 5
 SET_NPC_STAT absorb 10
 SET_NPC_STAT damages 5
 SET_NPC_STAT tohit 30
 SET_NPC_STAT aimtime 1000
 SET_NPC_STAT life 18
 SET_XP_VALUE 6

 SETIRCOLOR 0.8 0.0 0.0

 LOADANIM WALK                       "dog_walk"
 LOADANIM RUN                        "pig_run"
 LOADANIM WAIT                       "pig_wait"
 LOADANIM HIT                        "pig_gethit"
 LOADANIM HIT_SHORT                  "pig_hit_short"
 LOADANIM DIE                        "pig_death"

 ACCEPT
}

ON INITEND 
{
 IF (§dead == 1) ACCEPT
 TELEPORT -i
 BEHAVIOR WANDER_AROUND 1000
 SETTARGET NONE
 ACCEPT
}

ON COLLIDE_DOOR {
 HEROSAY -d "coldoor"
>>AWAY
 BEHAVIOR FLEE 200
 SETTARGET ^SENDER
 GOSUB SAVE_BEHAVIOR
 TIMERpathfail 1 2 GOSUB RESTORE_BEHAVIOR
 ACCEPT
}

ON COLLIDE_NPC {
GOTO AWAY
 ACCEPT
}

//START*******************************************************

ON SPELLCAST {
 IF (^SENDER != PLAYER) ACCEPT
 IF (^$PARAM1 == FIREBALL) SET §roti 1
 ACCEPT
}

ON SPELLEND {
 IF (^SENDER != PLAYER) ACCEPT
 IF (^$PARAM1 == FIREBALL) SET §roti 0
 ACCEPT
}

//*******************************************************
ON DETECTPLAYER 
{
 IF (^PLAYERSPELL_INVISIBILITY == 1) ACCEPT

 SET §player_in_sight 1
 SET_NPC_STAT BACKSTAB 0
 IF (§enemy == 1) GOTO FLEE

 ACCEPT
}

ON UNDETECTPLAYER
{
 SET §player_in_sight 0
}

//*******************************************************
ON FLEE_END 
{
 IF (§player_in_sight == 1) GOTO FLEE
 BEHAVIOR WANDER_AROUND 1000
 SETTARGET NONE
 SET §reflection_mode 1
 ACCEPT
}

//*******************************************************
ON AGRESSION
{
// GOTO OUCHSUITE
 GOTO OUCH_START
 ACCEPT
}

//*******************************************************
ON OUCH 
{
>>OUCH_START
 FORCEANIM HIT
 IF (^#PARAM1 >= 6) PLAY -p ~£ouch_strong~
 ELSE
 {
  IF (^#PARAM1 >= 3) PLAY -p ~£ouch_medium~
  ELSE PLAY -p ~£ouch~
 }
>>OUCHSUITE
 SET §enemy 1
 GOTO FLEE
}

>>FLEE
 SET §reflection_mode 0
 BEHAVIOR FLEE 1000
 SETTARGET PLAYER
 SETMOVEMODE RUN
ACCEPT

//********************************
ON MISC_REFLECTION 
{
 IF ( §reflection_mode == 0 ) ACCEPT
 IF ( #SHUT_UP == 1 ) ACCEPT
 SET #TMP ~^RND_6~
 INC #TMP 6
 TIMERmisc_reflection -i 0 ~#TMP~ SENDEVENT MISC_REFLECTION SELF ""
 RANDOM 40 ACCEPT
 SET £tmp ^RND_~§sound_amount~
 SET §sound ~£tmp~
 INC §sound 1
 IF (§sound > §sound_amount) SET §sound 1
 IF (§last_misc == §sound) {
  INC §sound 1
  IF (§sound > §sound_amount) SET §sound 1
 }
 SET §last_misc §sound
 PLAY -p ~£misc~~§sound~
 ACCEPT
}

//********************************

ON DIE 
{
 SET §dead 1
 INVENTORY CREATE  //specific
 IF (§roti == 1) 
 {
  INVENTORY ADD "\\provisions\\ribs_cooked\\ribs_cooked"
  INVENTORY ADD "\\provisions\\ribs_cooked\\ribs_cooked"
 }
 ELSE
 {
  INVENTORY ADD "\\provisions\\ribs\\ribs"
  INVENTORY ADD "\\provisions\\ribs\\ribs"
 }
 TIMERmisc_reflection OFF
 FORCEANIM DIE
 IF (£dying != "none") PLAY -p ~£dying~
 COLLISION OFF
 ACCEPT
}

ON FIRE_AFFRAID {
 IF (§flee == 1) ACCEPT
 SET §flee 1
 PLAY -p ~£dying~
 IF (§enemy == 0) {
  BEHAVIOR STACK
  TIMERrestore 1 8 IF (§enemy == 0) BEHAVIOR UNSTACK
 }
 IF (§enemy == 1) {
  TIMERattak 1 8 SET §enemy 1
  SET §enemy 0
  SET §fighting_mode 0
 }
 BEHAVIOR FLEE 1500
 SETTARGET PLAYER
 SETMOVEMODE RUN
 ACCEPT
}

//#behavior_animal

// ---------------------------------------------------------------------------------
// BEHAVIOR INCLUDE START ----------------------------------------------------------
// ---------------------------------------------------------------------------------
>>SAVE_BEHAVIOR
 TIMERcolplayer OFF // to avoid TIMERcolplayer to restore the behavior 1 sec later
 IF (§main_behavior_stacked == 0) 
 {
  IF (§frozen == 1)
  { // frozen anim -> wake up !
    SET §frozen 0
    PLAYANIM NONE
    PLAYANIM -2 NONE
    PHYSICAL ON
    COLLISION ON
    BEHAVIOR FRIENDLY
    SETTARGET PLAYER
  }
  SET §main_behavior_stacked 1
  HEROSAY -d "STACK"
  BEHAVIOR STACK
 }
RETURN

>>RESTORE_BEHAVIOR
 IF (§main_behavior_stacked == 1) 
 {
  HEROSAY -d "UNSTACK"
  BEHAVIOR UNSTACK
  SET §main_behavior_stacked 0
  RETURN
 }
 IF (£init_marker != "NONE")
  { 
   BEHAVIOR MOVE_TO
   SETTARGET -a ~£init_marker~
   SETMOVEMODE WALK
   RETURN
  }
 HEROSAY -d "go_home"
 BEHAVIOR GO_HOME
 SETTARGET PLAYER
 RETURN
// ---------------------------------------------------------------------------------
// BEHAVIOR INCLUDE END ------------------------------------------------------------
// ---------------------------------------------------------------------------------

//#
