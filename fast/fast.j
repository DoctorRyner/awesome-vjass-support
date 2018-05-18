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

library swift {
    void moveForward(unit target, float offset) {
        float angle = GetUnitFacing(target)
        SetUnitX(target, GetUnitX(target) + Cos(bj_DEGTORAD * angle) * offset)
        SetUnitY(target, GetUnitY(target) + Sin(bj_DEGTORAD * angle) * offset)    
    }
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