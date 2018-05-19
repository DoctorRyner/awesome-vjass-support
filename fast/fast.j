// timer lib

library TimerUtils initializer inita
//*********************************************************************
//* TimerUtils (red+blue+orange flavors for 1.24b+) 2.0
//* ----------
//*
//*  To implement it , create a custom text trigger called TimerUtils
//* and paste the contents of this script there.
//*
//*  To copy from a map to another, copy the trigger holding this
//* library to your map.
//*
//* (requires vJass)   More scripts: htt://www.wc3c.net
//*
//* For your timer needs:
//*  * Attaching
//*  * Recycling (with double-free protection)
//*
//* set t=NewTimer()      : Get a timer (alternative to CreateTimer)
//* set t=NewTimerEx(x)   : Get a timer (alternative to CreateTimer), call
//*                            Initialize timer data as x, instead of 0.
//*
//* ReleaseTimer(t)       : Relese a timer (alt to DestroyTimer)
//* SetTimerData(t,2)     : Attach value 2 to timer
//* GetTimerData(t)       : Get the timer's value.
//*                         You can assume a timer's value is 0
//*                         after NewTimer.
//*
//* Multi-flavor:
//*    Set USE_HASH_TABLE to true if you don't want to complicate your life.
//*
//* If you like speed and giberish try learning about the other flavors.
//*
//********************************************************************

//================================================================
    globals
        //How to tweak timer utils:
        // USE_HASH_TABLE = true  (new blue)
        //  * SAFEST
        //  * SLOWEST (though hash tables are kind of fast)
        //
        // USE_HASH_TABLE = false, USE_FLEXIBLE_OFFSET = true  (orange)
        //  * kinda safe (except there is a limit in the number of timers)
        //  * ALMOST FAST
        //
        // USE_HASH_TABLE = false, USE_FLEXIBLE_OFFSET = false (red)
        //  * THE FASTEST (though is only  faster than the previous method
        //                  after using the optimizer on the map)
        //  * THE LEAST SAFE ( you may have to tweak OFSSET manually for it to
        //                     work)
        //
        private constant boolean USE_HASH_TABLE      = true
        private constant boolean USE_FLEXIBLE_OFFSET = false

        private constant integer OFFSET     = 0x100000
        private          integer VOFFSET    = OFFSET
              
        //Timers to preload at map init:
        private constant integer QUANTITY   = 256
        
        //Changing this  to something big will allow you to keep recycling
        // timers even when there are already AN INCREDIBLE AMOUNT of timers in
        // the stack. But it will make things far slower so that's probably a bad idea...
        private constant integer ARRAY_SIZE = 8190

    endglobals

    //==================================================================================================
    globals
        private integer array data[ARRAY_SIZE]
        private hashtable     ht
    endglobals
    
    

    //It is dependent on jasshelper's recent inlining optimization in order to perform correctly.
    function SetTimerData takes timer t, integer value returns nothing
        static if(USE_HASH_TABLE) then
            // new blue
            call SaveInteger(ht,0,GetHandleId(t), value)
            
        elseif (USE_FLEXIBLE_OFFSET) then
            // orange
            static if (DEBUG_MODE) then
                if(GetHandleId(t)-VOFFSET<0) then
                    call BJDebugMsg("SetTimerData: Wrong handle id, only use SetTimerData on timers created by NewTimer")
                endif
            endif
            set data[GetHandleId(t)-VOFFSET]=value
        else
            // new red
            static if (DEBUG_MODE) then
                if(GetHandleId(t)-OFFSET<0) then
                    call BJDebugMsg("SetTimerData: Wrong handle id, only use SetTimerData on timers created by NewTimer")
                endif
            endif
            set data[GetHandleId(t)-OFFSET]=value
        endif        
    endfunction

    function GetTimerData takes timer t returns integer
        static if(USE_HASH_TABLE) then
            // new blue
            return LoadInteger(ht,0,GetHandleId(t) )
            
        elseif (USE_FLEXIBLE_OFFSET) then
            // orange
            static if (DEBUG_MODE) then
                if(GetHandleId(t)-VOFFSET<0) then
                    call BJDebugMsg("SetTimerData: Wrong handle id, only use SetTimerData on timers created by NewTimer")
                endif
            endif
            return data[GetHandleId(t)-VOFFSET]
        else
            // new red
            static if (DEBUG_MODE) then
                if(GetHandleId(t)-OFFSET<0) then
                    call BJDebugMsg("SetTimerData: Wrong handle id, only use SetTimerData on timers created by NewTimer")
                endif
            endif
            return data[GetHandleId(t)-OFFSET]
        endif        
    endfunction

    //==========================================================================================
    globals
        private timer array tT[ARRAY_SIZE]
        private integer tN = 0
        private constant integer HELD=0x28829022
        //use a totally random number here, the more improbable someone uses it, the better.
        
        private boolean       didinit = false
    endglobals
    private keyword inita

    //==========================================================================================
    // I needed to decide between duplicating code ignoring the "Once and only once" rule
    // and using the ugly textmacros. I guess textmacros won.
    //
    //! textmacro TIMERUTIS_PRIVATE_NewTimerCommon takes VALUE
    // On second thought, no.
    //! endtextmacro

    function NewTimerEx takes integer value returns timer
        if (tN==0) then
            if (not didinit) then 
                //This extra if shouldn't represent a major performance drawback
                //because QUANTITY rule is not supposed to be broken every day. 
                call inita.evaluate()
                set tN = tN - 1
            else
                //If this happens then the QUANTITY rule has already been broken, try to fix the
                // issue, else fail.
                debug call BJDebugMsg("NewTimer: Warning, Exceeding TimerUtils_QUANTITY, make sure all timers are getting recycled correctly")
                set tT[0]=CreateTimer()
                static if( not USE_HASH_TABLE) then
                    debug call BJDebugMsg("In case of errors, please increase it accordingly, or set TimerUtils_USE_HASH_TABLE to true")
                    static if( USE_FLEXIBLE_OFFSET) then
                        if (GetHandleId(tT[0])-VOFFSET<0) or (GetHandleId(tT[0])-VOFFSET>=ARRAY_SIZE) then
                            //all right, couldn't fix it
                            call BJDebugMsg("NewTimer: Unable to allocate a timer, you should probably set TimerUtils_USE_HASH_TABLE to true or fix timer leaks.")
                            return null
                        endif
                    else
                        if (GetHandleId(tT[0])-OFFSET<0) or (GetHandleId(tT[0])-OFFSET>=ARRAY_SIZE) then
                            //all right, couldn't fix it
                            call BJDebugMsg("NewTimer: Unable to allocate a timer, you should probably set TimerUtils_USE_HASH_TABLE to true or fix timer leaks.")
                            return null
                        endif
                    endif
                endif
            endif
        else
            set tN=tN-1
        endif
        call SetTimerData(tT[tN],value)
     return tT[tN]
    endfunction
    
    function NewTimer takes nothing returns timer
        return NewTimerEx(0)
    endfunction


    //==========================================================================================
    function ReleaseTimer takes timer t returns nothing
        if(t==null) then
            debug call BJDebugMsg("Warning: attempt to release a null timer")
            return
        endif
        if (tN==ARRAY_SIZE) then
            debug call BJDebugMsg("Warning: Timer stack is full, destroying timer!!")

            //stack is full, the map already has much more troubles than the chance of bug
            call DestroyTimer(t)
        else
            call PauseTimer(t)
            if(GetTimerData(t)==HELD) then
                debug call BJDebugMsg("Warning: ReleaseTimer: Double free!")
                return
            endif
            call SetTimerData(t,HELD)
            set tT[tN]=t
            set tN=tN+1
        endif    
    endfunction

    private function inita takes nothing returns nothing
     local integer i=0
     local integer o=-1
     local boolean oops = false
        if ( didinit ) then
            return
        else
            set didinit = true
        endif
     
        static if( USE_HASH_TABLE ) then
            set ht = InitHashtable()
            loop
                exitwhen(i==QUANTITY)
                set tT[i]=CreateTimer()
                call SetTimerData(tT[i], HELD)
                set i=i+1
            endloop
            set tN = QUANTITY
        else
            loop
                set i=0
                loop
                    exitwhen (i==QUANTITY)
                    set tT[i] = CreateTimer()
                    if(i==0) then
                        set VOFFSET = GetHandleId(tT[i])
                        static if(USE_FLEXIBLE_OFFSET) then
                            set o=VOFFSET
                        else
                            set o=OFFSET
                        endif
                    endif
                    if (GetHandleId(tT[i])-o>=ARRAY_SIZE) then
                        exitwhen true
                    endif
                    if (GetHandleId(tT[i])-o>=0)  then
                        set i=i+1
                    endif
                endloop
                set tN = i
                exitwhen(tN == QUANTITY)
                set oops = true
                exitwhen not USE_FLEXIBLE_OFFSET
                debug call BJDebugMsg("TimerUtils_init: Failed a initialization attempt, will try again")               
            endloop
            
            if(oops) then
                static if ( USE_FLEXIBLE_OFFSET) then
                    debug call BJDebugMsg("The problem has been fixed.")
                    //If this message doesn't appear then there is so much
                    //handle id fragmentation that it was impossible to preload
                    //so many timers and the thread crashed! Therefore this
                    //debug message is useful.
                elseif(DEBUG_MODE) then
                    call BJDebugMsg("There were problems and the new timer limit is "+I2S(i))
                    call BJDebugMsg("This is a rare ocurrence, if the timer limit is too low:")
                    call BJDebugMsg("a) Change USE_FLEXIBLE_OFFSET to true (reduces performance a little)")
                    call BJDebugMsg("b) or try changing OFFSET to "+I2S(VOFFSET) )
                endif
            endif
        endif

    endfunction

endlibrary

// end timer lib

// MAIN

// def_timer

define newTimer = NewTimer
define startTimer = TimerStart
define setObjToSend = SetTimerData
define getSendedObj = GetTimerData
define getTimer = GetExpiredTimer
define catchTimerObj() = {
    thistype this = GetTimerData(GetExpiredTimer())
}

define stopTimer = ReleaseTimer(GetExpiredTimer())

define stopTimerNamed(timerName) = ReleaseTimer(timerName)

define runTimer(period, isPeriodic, actFunc) = {
    timer runTimer_timer = NewTimer()
    TimerStart(runTimer_timer, period, isPeriodic, actFunc)
    SetTimerData(runTimer_timer, this)
    runTimer_timer = null
}

define runTimerNamed(name, period, isPeriodic, actFunc) = {
    timer name = NewTimer()
    TimerStart(name, period, isPeriodic, actFunc)
    SetTimerData(name, this)
    name = null
}

define runTimerNamedObj(name, obj, period, isPeriodic, actFunc) = {
    timer name = NewTimer()
    TimerStart(name, period, isPeriodic, actFunc)
    SetTimerData(name, obj)
    name = null
}

define vstatic = static void
// enddef_timer

//

define newUnit = CreateUnit

//

// cJass lib declaration 
include "cj_types_priv.j"
include "cj_antibj_base.j"

define event = trigger

define class = private struct
define <just class> = struct
define <public class> = public struct

setdef <void> = private nothing
define <just void> = nothing
define <public void> = public nothing
define <public static void> = public static nothing
define <static void> = private static nothing

// constructor
// define onCreate = public static thistype create
define onCreate = {
        public static method create takes nothing returns thistype
    tt this = allocate()
}

define end = {
    return this
    endmethod
}

define onCreateCustom = public static thistype create
define custom = thistype this = allocate()
define endcustom = return this

define tt = thistype

define <public class> = public struct

// timer data sendedObj
define sendedObj = data

define p1 = Player(0)
define p2 = Player(1)
define p3 = Player(2)
define p4 = Player(3)
define p5 = Player(4)
define p6 = Player(5)
define p7 = Player(6)
define p8 = Player(7)
define p9 = Player(8)
define p10 = Player(9)
define p11 = Player(10)
define p12 = Player(11)

define <lib> = scope

define with = requires

define fast = initializer onInit

define init = void onInit()

define str = string
define flo = float
define flt = float

define EVENT_UNIT_USED_SPELL = EVENT_PLAYER_UNIT_SPELL_EFFECT

// trigger

event newUnitEvent(playerunitevent gottenEvent, code action) {
    event e = newEvent()
    TriggerRegisterAnyUnitEventBJ(e, gottenEvent)
    TriggerAddAction(e, action)
    return e
}

event newSingleUnitEvent(unitevent gottenEvent, unit gottenUnit, code action) {
    event e = newEvent()
    TriggerRegisterUnitEvent(e, gottenUnit, gottenEvent)
    TriggerAddAction(e, action)
    return e
}

event newTimeEvent(float time, bool isPeriodic) {
    event e = newEvent()
    TriggerRegisterTimerEvent(e, time, isPeriodic)
    return e
}

event newPlayerEvent(player gottenPlayer, playerevent gottenPlayerEvent) {
    event e = newEvent()
    TriggerRegisterPlayerEvent(e, gottenPlayer, gottenPlayerEvent)
    return e
}

define GroupAddGroup = copyGroup

define newEvent = CreateTrigger
define newGroup = CreateGroup
define getX = GetUnitX
define getY = GetUnitY
define select(unit_to_select) = SelectUnit(unit_to_select, true)
define unselect(unit_to_select) = SelectUnit(unit_to_select, false)

define addUnitEvent = TriggerRegisterAnyUnitEventBJ

define func = function

define addAction(t, f) = TriggerAddAction(t, f)

define printTo(gottenPlayer, text) = DisplayTextToPlayer(gottenPlayer, 0, 0, text)

define print(text) = BJDebugMsg(text)

define setAngle = SetUnitFacing
define getAngle = GetUnitFacing

// gets

define getCaster = GetSpellAbilityUnit
define getSpellId = GetSpellAbilityId
define getOwner = GetOwningPlayer
define getTarget = GetSpellTargetUnit
define getSpellX = GetSpellTargetX
define getSpellY = GetSpellTargetY
define getState = GetUnitState
define setState = SetUnitState

library swift {
    just void moveForward(unit target, float offset) {
        float angle = GetUnitFacing(target)
        SetUnitX(target, GetUnitX(target) + Cos(bj_DEGTORAD * angle) * offset)
        SetUnitY(target, GetUnitY(target) + Sin(bj_DEGTORAD * angle) * offset)    
    }
    float TIME_STD = 0.025
}

just class Math {
    public static float root(float gottenNumber) { return SquareRoot(gottenNumber) }

    public static float angleBetweenPoints(float ax, float ay, float bx, float by) { return bj_RADTODEG * Atan2(by - ay, bx - ax) }

    public static float angleBetweenUnitPoint(unit target, float x, float y) { return bj_RADTODEG * Atan2(getY(target) - y, getX(target) - x) }

    public static float angleBetweenUnits(unit a, unit b) { return bj_RADTODEG * Atan2(getY(b) - getY(a), getX(b) - getX(a)) }
}

just class Distance {
    float min, cur, max, period

    onCreateCustom(float gottenMin, float gottenMax, float gottenPeriod) {
        custom
        min = gottenMin
        cur = min
        max = gottenMax
        period = gottenPeriod
        endcustom
    }
}

just class Vector2 {
    float x, y

    public float length() { return Math.root((x * x) + (y * y)) }
    public void norm() {
        float m = Math.root(length())
        x /= m
        y /= m
    }

    public void plus(Vector2 gottenVector) {
        x += gottenVector.x
        y += gottenVector.y
    }

    public void multiply(float times) {
        x *= times
        y *= times
    }
    
    public static Vector2 getFromPoints(float ax, float ay, float bx, float by) {
        Vector2 v = Vector2.create()
        v.x = bx - ax
        v.y = by - ay
        return v
    }

    public static Vector2 getFromUnits(unit a, unit b) {
        Vector2 v = Vector2.create()
        v.x = getX(b) - getX(a)
        v.y = getY(b) - getY(a)
        return v
    }

    public static Vector2 getFromUnitPoint(unit target, float x, float y) {
        Vector2 v = Vector2.create()
        v.x = x - getX(target)
        v.y = y - getY(target)
        return v
    }

    public static void move(unit target, float speed, Vector2 dir) {
        moveAt(target, getX(target) + dir.x, getY(target) + dir.y)
    }
}

define moveToward(target, offset, angle) = {
    SetUnitX(target, GetUnitX(target) + Cos(bj_DEGTORAD * angle) * offset)
    SetUnitY(target, GetUnitY(target) + Sin(bj_DEGTORAD * angle) * offset)
}

define moveAt(target, x, y) = {
    SetUnitX(target, x)
    SetUnitY(target, y)
}

define damage(source, target, damageAmount) = UnitDamageTarget(source, target, damageAmount, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)