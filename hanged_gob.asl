ON INIT {
 SETNAME [description_hanged_gob]
 SET_MATERIAL FLESH
 LOADANIM ACTION1 "hanged_gob"
 ACCEPT
}

ON ACTION {
 PLAYANIM ACTION1
 ACCEPT
}
