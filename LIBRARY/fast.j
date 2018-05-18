// timer lib

library Timer

//! novjass

static method start takes integer user_data, real timeout, code callback returns Timer

method stop takes nothing returns nothing


method pause takes nothing returns nothing

static method getSendedObj takes nothing returns integer

static method getSendedTimer takes nothing returns Timer

method restart takes code callback returns nothing

//! endnovjass

struct Timer extends array
    readonly static integer max_count = 0
    readonly static integer curr_count = 0

    private static Timer head = 0
    private Timer next

    private timer t
    integer data
    real timeout

    static method start takes integer user_data, real timeout, code callback returns Timer
        local Timer this

        if head != 0 then
            set this = head
            set head = head.next

        else
            set max_count = max_count + 1
            if max_count > 8190 then
static if DEBUG_MODE then
                call DisplayTimedTextToPlayer(GetLocalPlayer(), 0.0, 0.0, 1000.0, "|cffFF0000[Timer] error: could not allocate a Timer instance|r")
endif
                return 0
            endif

            set this = max_count
            set this.t = CreateTimer()
        endif
        set curr_count = curr_count + 1

        set this.next = 0
        set this.data = user_data
        set this.timeout = timeout

        call TimerStart(this.t, this, false, null)
        call PauseTimer(this.t)
        call TimerStart(this.t, timeout, false, callback)

        return this
    endmethod

    method stop takes nothing returns nothing
        if this == 0 then
static if DEBUG_MODE then
        call DisplayTimedTextToPlayer(GetLocalPlayer(), 0.0, 0.0, 1000.0, "|cffFF0000[Timer] error: cannot stop null Timer instance|r")
endif
            return
        endif

        if this.next != 0 then
static if DEBUG_MODE then
        call DisplayTimedTextToPlayer(GetLocalPlayer(), 0.0, 0.0, 1000.0, "|cffFF0000[Timer] error: cannot stop Timer(" + I2S(this) + ") instance more than once|r")
endif
            return
        endif

        set curr_count = curr_count - 1

        call TimerStart(this.t, 0.0, false, null)
        set this.next = head
        set head = this
    endmethod

    method pause takes nothing returns nothing
        call TimerStart(this.t, 0.0, false, null)
    endmethod

    static method getSendedTimer takes nothing returns Timer
        return R2I(TimerGetRemaining(GetExpiredTimer()) + 0.5)
    endmethod

    static method getSendedObj takes nothing returns integer
        local Timer t = Timer( R2I(TimerGetRemaining(GetExpiredTimer()) + 0.5) )
        local integer data = t.data
        call t.stop()
        return data
    endmethod

    method restart takes code callback returns nothing
        call TimerStart(this.t, this.data, false, null)
        call PauseTimer(this.t)
        call TimerStart(this.t, this.timeout, false, callback)
    endmethod

endstruct

endlibrary

// end timer lib

// cJass lib declaration 
#include "cj_types_priv.j"

define class = struct

// constructor
define <onCreate> = public static thistype create
define begin = thistype this = allocate()
define end = return this

define tt = thistype

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

define init = private void onInit()

define str = string

define cast = create

define EVENT_UNIT_USED_SPELL = EVENT_PLAYER_UNIT_SPELL_EFFECT

// trigger

define newUnitTrigger(t, event, action) = { 
    trigger t = CreateTrigger()
    TriggerRegisterAnyUnitEventBJ(t, event)
    TriggerAddAction(t, action)
}

define newSingleUnitTrigger(t, event, action) = { 
    trigger t = CreateTrigger()
    TriggerRegisterUnitEvent(t, event)
    TriggerAddAction(t, action)
}

//define newTrigger = CreateTrigger
define newGroup = CreateGroup
define getX = GetUnitX
define getY = GetUnitY
define select(unit_to_select) = SelectUnit(unit_to_select, true)
define unselect(unit_to_select) = SelectUnit(unit_to_select, false)

define addUnitEvent = TriggerRegisterAnyUnitEventBJ

define func = function

define addAction(t, f) = TriggerAddAction(t, f)

define printTo(text, gottenPlayer) = DisplayTextToPlayer(gottenPlayer, 0, 0, text)

define print(text) = BJDebugMsg(text)

define getCaster = GetSpellAbilityUnit
define getSpellId = GetSpellAbilityId
define getOwner = GetOwningPlayer

library swift {
    void move(unit target, float offset) {
        float targetFacing = GetUnitFacing(target)
        float x = GetUnitX(target) + Cos(bj_DEGTORAD * targetFacing) * offset
        float y = GetUnitY(target) + Sin(bj_DEGTORAD * targetFacing) * offset
        SetUnitX(target, x)
        SetUnitY(target, y) 
    }

    void moveAt(unit target, float x, float y) {
        SetUnitX(target, x)
        SetUnitY(target, y)
    }
}

define damage(source, target, damageAmount) = UnitDamageTarget(source, target, damageAmount, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)