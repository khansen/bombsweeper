;
;    Copyright (C) 2002, 2004 Kent Hansen.
;
;    This file is part of BombSweeper.
;
;    BombSweeper is free software; you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation; either version 2 of the License, or
;    (at your option) any later version.
;
;    BombSweeper is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program; if not, write to the Free Software
;    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;

.codeseg

.charmap "bombswpr.tbl"

.public NMI, RESET, IRQ

;--------------------------------[ Defines ]----------------------------------

; Hardware reg defs

PPUCtrl0                EQU     $2000
PPUCtrl1                EQU     $2001
PPUStat                 EQU     $2002
SPRAddr                 EQU     $2003
SPRIOReg                EQU     $2004
PPUScroll               EQU     $2005
PPUAddr                 EQU     $2006
PPUIOReg                EQU     $2007
SPRDMAReg               EQU     $4014
JoyReg                  EQU     $4016

; Constants

NULL                    EQU     0
TIMER_SPEED             EQU     6
BLANK_TILE              EQU     $00
NUM_LEVELS              EQU     99

; Zero page defs

ScrollX                 EQU     $00
ScrollY                 EQU     $01
ZPCtrl0                 EQU     $02
ZPCtrl1                 EQU     $03
NMIRoutine              EQU     $04
MainRoutine             EQU     $05
IRQRoutine              EQU     $06
FrameStat               EQU     $07
FrameCount              EQU     $08
JoyStat                 EQU     $0C
JoyFirst                EQU     $0D
MenuSelect              EQU     $0E
DemoNumber              EQU     $0F
ScreenX                 EQU     $10
ScreenY                 EQU     $11
SpriteBase              EQU     $12
SpriteIndex             EQU     $13
CelLength               EQU     $14
Timer                   EQU     $15     ; 8 bytes
TimerDelay              EQU     $1D
PPUDataPending          EQU     $1E
Temp                    EQU     $1F
Temp2                   EQU     $20
Temp3                   EQU     $21
Temp4                   EQU     $22
Count                   EQU     $23
Count2                  EQU     $24
Count3                  EQU     $25
pLevel                  EQU     $26
LevelOfs                EQU     $28
LevelByte               EQU     $29
BitsCount               EQU     $2A
Level                   EQU     $2B
NextRoutine             EQU     $2C
PPUStrIndex             EQU     $2D
DesignMode              EQU     $37
DemoMode                EQU     $38
Index                   EQU     $39
Index2                  EQU     $3A
Index3                  EQU     $3B
Index4                  EQU     $3C
BombX                   EQU     $40
BombY                   EQU     $48
GridX                   EQU     $50
GridY                   EQU     $51
Score                   EQU     $52
TopScore                EQU     $56
pLevelData              EQU     $5A
GameType                EQU     $5C ; 0 = Game A, 1 = Game B
BombTick                EQU     $5D
BombTimerReset          EQU     $5E
BombTimer               EQU     $5F
LivesLeft               EQU     $60
GridOfs                 EQU     $61
BombCount               EQU     $62
BombsLeft               EQU     $63
CelNum                  EQU     $64
LevelTheme              EQU     $65
MenuCursorX             EQU     $66
MenuCursorY             EQU     $67
MenuItems               EQU     $68
TextureTile             EQU     $69
ComboPos                EQU     $6A
LevelCheatEnabled       EQU     $6B
BombCelNum              EQU     $6C
pCel                    EQU     $F8
pVRAM                   EQU     $FA
pCode                   EQU     $FC
pData                   EQU     $FE

PPUString               EQU     $0100
RAMPalette              EQU     $0160

; Sprite RAM defs

SPR_PosX                EQU     $0203
SPR_PosY                EQU     $0200
SPR_Tile                EQU     $0201
SPR_Attrib              EQU     $0202

; Joy pad defs

btnRIGHT                EQU     %00000001
btnLEFT                 EQU     %00000010
btnDOWN                 EQU     %00000100
btnUP                   EQU     %00001000
btnSTART                EQU     %00010000
btnSELECT               EQU     %00100000
btnB                    EQU     %01000000
btnA                    EQU     %10000000

; main routines

mrTitleInit             EQU     0
mrTitleMain             EQU     1
mrGameInit              EQU     2
mrLevelInit             EQU     3
mrLevelMain             EQU     4
mrPlayDemo              EQU     5
mrGameOverInit          EQU     6
mrGameOverMain          EQU     7
mrTheEndInit            EQU     8
mrTheEndMain            EQU     9
mrDesignMenuInit        EQU     10
mrDesignMenuMain        EQU     11
mrDesignInit            EQU     12
mrDesignMain            EQU     13
mrPauseMain             EQU     14
mrScoreMain             EQU     15
mrNextLevel             EQU     16
mrWaitTimer             EQU     17

; DEMOREC EQU 1 ; uncomment to record demo

;--------------------------------[ Code ]-------------------------------------

;.base $C000

        TitleInit:
        jsr     ScreenOff
        jsr     ClearDisplay
        lda     ZPCtrl0
        and     #$FC            ; nametable address = $2000
        sta     ZPCtrl0
        lda     #0
        sta     ScrollX
        sta     ScrollY
        sta     MenuSelect
        sta     DemoMode
        sta     DesignMode
        sta     ComboPos
        lda     #1
        sta     Level
        lda     #50
        sta     Timer
        lda     #<TitleData
        ldy     #>TitleData
        jsr     WriteROMPPUString
        lda     #<TitlePal
        ldy     #>TitlePal
        jsr     PAL_LoadPalette
        lda     #3
        sta     MenuItems
        lda     #95
        sta     MenuCursorY
        lda     #88
        sta     MenuCursorX
        jsr     SetMenuCursor
;
        lda     #1      ; title music
        sta     RNME_LoadTune
        jsr     ScreenOn
        inc     MainRoutine
        jmp     PAL_FadeFromBlack

;-------------------------[ Title screen main loop ]--------------------------

        TitleMain:
; see if it's time to start game demo
        lda     Timer
        beq     BeginDemo
; check for button presses
        lda     JoyFirst
        beq     @@10
        ldy     #50
        sty     Timer       ; reset demo timer
        and     #btnSTART
        beq     @@20
        jmp     TitleStartPressed
  @@20: lda     LevelCheatEnabled
        beq     @@30
        jsr     CheckLevelChange
        jmp     @@40
  @@30: jsr     CheckButtonCombo
  @@40: jsr     MenuHandler
  @@10: jmp     SetMenuCursor

        BeginDemo:
        jsr     PAL_FadeToBlack
        lda     DemoNumber
        inc     DemoNumber
        and     #3
        tax
        ldy     DemoLevels,x
        sty     Level
        asl
        tax
        lda     GameDemos,x
        sta     pDemo
        lda     GameDemos+1,x
        sta     pDemo+1
        lda     #1
        sta     JoyCount
        sta     DemoMode
        bne     Skippy

        TitleStartPressed:
        jsr     PAL_FadeToBlack
        ldy     MenuSelect
        beq     BeginGameA
        dey
        beq     BeginGameB
        dey
        beq     BeginDesign
        rts

        BeginGameA:
        lda     #0
        sta     GameType
        Skippy:
        lda     #50
        sta     BombTimerReset
        lda     #<GameA_LevelData
        sta     pLevelData
        lda     #>GameA_LevelData
        sta     pLevelData+1
        jmp     BeginGameForReal

        BeginGameB:
        lda     #1
        sta     GameType
        lda     #40
        sta     BombTimerReset
        lda     #<GameB_LevelData
        sta     pLevelData
        lda     #>GameB_LevelData
        sta     pLevelData+1
        BeginGameForReal:
        lda     #mrGameInit
        sta     MainRoutine
        rts

        BeginDesign:
        lda     #1
        sta     Level
        lda     #mrDesignMenuInit
        sta     MainRoutine
        rts

    ; see if player wants to change start level
        CheckLevelChange:
        lda     JoyFirst
        and     #(btnA | btnRIGHT)
        beq     @@10
    ; next level
        lda     Level
        inc     Level
        cmp     #NUM_LEVELS
        bne     @@20
        lda     #1
        sta     Level
  @@20: lda     #$21
        ldy     #$96
        jsr     PrintLevel
  @@10: lda     JoyFirst
        and     #(btnB | btnLEFT)
        beq     @@30
    ; previous level
        dec     Level
        bne     @@40
        lda     #NUM_LEVELS
        sta     Level
  @@40: lda     #$21
        ldy     #$96
        jsr     PrintLevel
  @@30: rts

        SetMenuCursor:
        lda     MenuSelect
        asl
        asl
        asl
        asl
        adc     MenuCursorY
        sta     SPR_PosY
        lda     MenuCursorX
        sta     SPR_PosX
        lda     #$68
        sta     SPR_Tile
        lda     #0
        sta     SPR_Attrib
        rts

        MenuHandler:
        lda     JoyFirst
        and     #(btnSELECT | btnDOWN)
        bne     NextMenuItem
        lda     JoyFirst
        and     #btnUP
        bne     PrevMenuItem
        rts
        NextMenuItem:
        ldy     MenuSelect
        iny
        cpy     MenuItems
        bne     @@10
        ldy     #0
  @@10: sty     MenuSelect
        rts
        PrevMenuItem:
        ldy     MenuSelect
        bne     @@20
        ldy     MenuItems
  @@20: dey
        sty     MenuSelect
        rts

        InitUserLevels:
        lda     #$00
        sta     pLevelData
        lda     #$03
        sta     pLevelData+1
        lda     #NUM_LEVELS
        sta     Count
        ldy     #0
  @@10: ldx     #0
  @@20: lda     TemplateLevel,x
        sta     [pLevelData],y
        inx
        iny
        bne     @@30
        inc     pLevelData+1
  @@30: cpx     #10
        bne     @@20
        dec     Count
        bne     @@10
        rts

        CheckButtonCombo:
        lda     JoyFirst
        beq     @@10               ; exit if no buttons pressed
        ldy     ComboPos
        lda     JoyFirst
        and     ButtonCombo,y
        bne     @@20
  @@30: lda     #0
        sta     ComboPos
        rts
  @@20: lda     ButtonCombo,y
        eor     #$FF
        sta     Temp
        lda     JoyFirst
        and     Temp
        bne     @@30
        inc     ComboPos
        lda     ComboPos
        cmp     #8
        beq     @@40
  @@10: rts
        ; enable level cheat
  @@40: lda     #1
        sta     LevelCheatEnabled
        lda     #3
        sta     SFX_Number
        lda     #$21
        ldy     #$96
        jmp     PrintLevel

;---------------------------[ External sources ]------------------------------

.incsrc "pal.inc"
;.incsrc "obj.inc"
;.incsrc "anim.inc"
.incsrc "rnme.inc"

;--------------------------[ Program entrypoint ]-----------------------------

        RESET:
        cld                     ; clear decimal mode
        ldx     #$00
        stx     PPUCtrl0        ; disable NMI and stuff
        stx     PPUCtrl1        ; disable BG & SPR visibility and stuff
        dex                     ; X = FF
        txs                     ; S points to end of stack page (1FF)
  @@10: lda     PPUStat
        bpl     @@10
  @@20: lda     PPUStat
        bpl     @@20
        lda     #$C0
        sta     $4017           ; disable erratic IRQ triggering
        jsr     ClearRAM
        jsr     InitUserLevels
        lda     #%00000110      ; Screen off
                                ; no BG+SPR clipping
                                ; Colour display
        sta     ZPCtrl1
        sta     PPUCtrl1
        lda     #%10001000      ; NMI = enabled
                                ; Sprite size = 8x8
                                ; BG pattern table = $0000
                                ; SPR pattern table = $1000
                                ; PPU address increment = 1
                                ; Name table address = $2000
        sta     ZPCtrl0
        sta     PPUCtrl0
        lda     #mrTitleInit
        sta     MainRoutine
        jmp     Entrypoint

;-----------------------------[ The main loop ]-------------------------------

        MainLoop:
        jsr     UpdateTimers
        jsr     GoMainHandler
        Entrypoint:
        jsr     WaitNMIPass
        jmp     MainLoop

;------------------------------[ Subroutines ]--------------------------------

; DrawCel
; =======

        DrawCel:
        stx     ScreenX
        sty     ScreenY
        asl
        tax
        lda     CelPtrTable,x
        sta     pCel
        lda     CelPtrTable+1,x
        sta     pCel+1
        ldy     #0
        lda     [pCel],y           ; # of sprites in the cel
        iny
        sta     CelLength
        ldx     SpriteIndex             ; X = index into sprite RAM

; Loop which draws all sprites that make up the cel, one at a time
; ... this should be as FAST as possible, since it might be executed
; up to 64 times per frame!! (not very likely though)

        ANIM_DrawOneSprite:
; 1st byte [Y coord]
        lda     [pCel],y   ; signed Y coord relative to obj's center
        iny
        clc
        adc     ScreenY         ; add obj's Y coord to get sprite's Y coord
        sta     SPR_PosY,x
; 2nd byte [tile value]
        lda     [pCel],y
        iny
        sta     SPR_Tile,x
; 3rd byte [attributes]
        lda     [pCel],y
        iny
        sta     SPR_Attrib,x
; 4th byte [X coord]
        lda     [pCel],y   ; signed X coord relative to obj's center
        iny
        clc
        adc     ScreenX
        sta     SPR_PosX,x
        txa
        clc
        adc     #15*4
        tax                     ; X is now ready to index next sprite
        dec     CelLength       ; done all sprites?
        bne     ANIM_DrawOneSprite
        stx     SpriteIndex     ; store new position in sprite RAM
        rts

; SetLevelPtr
; ===========

        SetLevelPtr:
        ldy     Level
        lda     #0
        tax
        clc
  @@10: dey
        beq     @@20
        adc     #10
        bcc     @@10
        inx
        clc
        bcc     @@10
  @@20: clc
        adc     pLevelData
        sta     pLevel
        txa
        adc     pLevelData+1
        sta     pLevel+1
        rts

; SetLevelTheme
; =============

        SetLevelTheme:
        lda     Level
        ldy     #0
        sec
  @@10: sbc     #10
        bcc     @@20
        iny
        bne     @@10
  @@20: sty     LevelTheme
        tya
        ora     #$40
        sta     TextureTile
        rts

; RenderLevel
; ===========

        RenderLevel:
; clear the playfield
        lda     #$20
        sta     pVRAM+1
        lda     #$83
        sta     pVRAM
        lda     #17
        sta     Count
  @@10: ldx     PPUStrIndex
        lda     pVRAM+1
        sta     PPUString,x
        inx
        lda     pVRAM
        sta     PPUString,x
        inx
        lda     #$59
        sta     PPUString,x
        inx
        lda     TextureTile
        sta     PPUString,x
        inx
        jsr     EndPPUString
        jsr     CheckPPUWrite
        lda     pVRAM
        clc
        adc     #$20
        sta     pVRAM
        bcc     @@20
        inc     pVRAM+1
  @@20: dec     Count
        bne     @@10
;
        lda     #0
        sta     Index3
        sta     BitsCount
        sta     LevelOfs
        sta     GridY
        DrawOneRow:
        lda     #0
        sta     GridX
        DrawOneCell:
        jsr     GetCellCode
        ldy     Index3
        sta     $80,y
        inc     Index3
        lsr
        pha
        bcc     @@10
        ldx     GridX
        ldy     GridY
        jsr     DrawHorizontalWall
  @@10: pla
        lsr
        bcc     @@20
        ldx     GridX
        ldy     GridY
        jsr     DrawVerticalWall
  @@20: jsr     CheckPPUWrite
        inc     GridX
        lda     GridX
        cmp     #7
        bne     DrawOneCell
        inc     GridY
        lda     GridY
        cmp     #5
        bne     DrawOneRow
        rts

; GetCellCode
; ===========

        GetCellCode:
        dec     BitsCount
        bpl     @@10
        lda     #3
        sta     BitsCount
        ldy     LevelOfs
        lda     [pLevel],y
        sta     LevelByte
        inc     LevelOfs
  @@10: lda     LevelByte
        and     #3
        lsr     LevelByte
        lsr     LevelByte
        rts

        DrawHorizontalWall:
        jsr     SetGridVRAMAddr
        ldx     PPUStrIndex
        lda     pVRAM+1
        sta     PPUString,x
        inx
        lda     pVRAM
        sta     PPUString,x
        inx
        lda     #$04
        sta     PPUString,x
        inx
        lda     TextureTile
        sta     PPUString,x
        inx
        lda     #$02
        sta     PPUString,x
        inx
        lda     #$03
        sta     PPUString,x
        inx
        lda     #$04
        sta     PPUString,x
        inx
        jmp     EndPPUString

        DrawVerticalWall:
        jsr     SetGridVRAMAddr
        ldx     PPUStrIndex
        lda     pVRAM+1
        sta     PPUString,x
        inx
        lda     pVRAM
        sta     PPUString,x
        inx
        lda     #$84
        sta     PPUString,x
        inx
        lda     TextureTile
        sta     PPUString,x
        inx
        lda     #$05
        sta     PPUString,x
        inx
        lda     #$06
        sta     PPUString,x
        inx
        lda     #$07
        sta     PPUString,x
        inx
        jmp     EndPPUString

        EraseHorizontalWall:
        jsr     SetGridVRAMAddr
        ldx     PPUStrIndex
        lda     pVRAM+1
        sta     PPUString,x
        inx
        lda     pVRAM
        sta     PPUString,x
        inx
        lda     #$44
        sta     PPUString,x
        inx
        lda     TextureTile
        sta     PPUString,x
        inx
        jmp     EndPPUString

        EraseVerticalWall:
        jsr     SetGridVRAMAddr
        ldx     PPUStrIndex
        lda     pVRAM+1
        sta     PPUString,x
        inx
        lda     pVRAM
        sta     PPUString,x
        inx
        lda     #$C4
        sta     PPUString,x
        inx
        lda     TextureTile
        sta     PPUString,x
        inx
        jmp     EndPPUString

; PrintLevel
; ==========

        PrintLevel:
        ldx     Level
        stx     AC0
        ldx     #0
        stx     AC1
        stx     AC2
        ldx     #2
        jmp     PrintValue

; PrintLives
; ==========

        PrintLives:
        lda     LivesLeft
        sta     AC0
        lda     #0
        sta     AC1
        sta     AC2
        ldx     #1
        lda     #$23
        ldy     #$57
        jmp     PrintValue

; PrintScore
; ==========

        PrintScore:
        lda     Score
        sta     AC0
        lda     Score+1
        sta     AC1
        lda     Score+2
        sta     AC2
        ldx     #6
        lda     #$23
        ldy     #$22
        jmp     PrintValue

; PrintTopScore
; =============

        PrintTopScore:
        lda     TopScore
        sta     AC0
        lda     TopScore+1
        sta     AC1
        lda     TopScore+2
        sta     AC2
        ldx     #6
        lda     #$23
        ldy     #$2C
        jmp     PrintValue

; PrintBombTimer
; ==============

        PrintBombTimer:
        lda     BombTimer
        sta     AC0
        lda     #0
        sta     AC1
        ldx     #2
        lda     #$23
        ldy     #$5A
        jmp     PrintValue

; PrintValue
; ==========
; AC0, AC1 = value to print
; X = # of digits to output
; A = PPU high address
; Y = PPU low address

        PrintValue:
        stx     Count
        ldx     PPUStrIndex
        sta     PPUString,x
        inx
        tya
        sta     PPUString,x
        inx
        lda     Count
        sta     PPUString,x
        inx
        lda     #10
        sta     AUX0
        lda     #0
        sta     AUX1
        sta     AUX2
        ldy     Count
        cpy     #0
        bne     @@10
    ; figure out how many digits to print
  @@20: iny
        cpy     #7
        beq     @@10
        lda     AC0
        sec
        sbc     DecPos0-1,y
        lda     AC1
        sbc     DecPos1-1,y
        lda     AC2
        sbc     DecPos2-1,y
        bcs     @@20
  @@10: sty     Count
  @@30: jsr     Divide
        lda     XTND0
        pha
        dey
        bne     @@30
  @@40: pla
        ora     #$D0
        sta     PPUString,x
        inx
        iny
        cpy     Count
        bne     @@40
        jmp     EndPPUString

DecPos0:
.db $0A,$64,$E8,$10,$A0,$40
DecPos1:
.db $00,$00,$03,$27,$86,$42
DecPos2:
.db $00,$00,$00,$00,$01,$0F

AC0    EQU $B6  ; initial dividend & resulting quotient
AC1    EQU $B7
AC2    EQU $B8
XTND0  EQU $B9  ; remainder
XTND1  EQU $BA
XTND2  EQU $BB
AUX0   EQU $BC  ; divisor
AUX1   EQU $BD
AUX2   EQU $BE
TMP0   EQU $BF

        Divide:
        txa
        pha
        tya
        pha
        ldy #24      ; bitwidth
        lda #0
        sta XTND0
        sta XTND1
        sta XTND2
  @@10: asl AC0      ;DIVIDEND/2, CLEAR QUOTIENT BIT
        rol AC1
        rol AC2
        rol XTND0
        rol XTND1
        rol XTND2
        lda XTND0    ;TRY SUBTRACTING DIVISOR
        sec
        sbc AUX0
        sta TMP0
        lda XTND1
        sbc AUX1
        tax
        lda XTND2
        sbc AUX2
        bcc @@20     ;TOO SMALL, QBIT=0
        stx XTND1    ;OKAY, STORE REMAINDER
        sta XTND2
        lda TMP0
        sta XTND0
        inc AC0      ;SET QUOTIENT BIT = 1
  @@20: dey          ;NEXT STEP
        bne @@10
        pla
        tay
        pla
        tax
        rts
        
; ScreenOff
; =========
; Turns off both background and sprites, so that VRAM can safely be written
; to.

        ScreenOff:
        lda     ZPCtrl1
        and     #%11100111      ; bg & sprite visibility = false
        sta     ZPCtrl1

; WaitNMIPass
; ===========
; Hangs around until the NMI has finished.
; NMI *must* be enabled when this routine is called, otherwise it will go
; into an infinite loop.

        WaitNMIPass:
        lda     #$00
        sta     FrameStat
  @@10: lda     FrameStat
        beq     @@10
        rts

; ScreenOn
; ========
; Enables both background and sprites.

        ScreenOn:
        lda     ZPCtrl1
        ora     #%00011000      ; bg & sprite visibility = true
        sta     ZPCtrl1
        bne     WaitNMIPass

; UpdateTimers
; ============
; Decrements Timer every (1/60)*TIMER_SPEED seconds (AKA every TIMER_SPEEDth
; frame), if it isn't already zero.

        UpdateTimers:
        dec     TimerDelay
        bpl     @@10
        lda     #TIMER_SPEED-1
        sta     TimerDelay
        ldx     #$07            ; 8 timers to update
  @@20: lda     Timer,x
        beq     @@30            ; don't modify if already zero
        dec     Timer,x
  @@30: dex                     ; next timer
        bpl     @@20
  @@10: rts

; ClearDisplay
; ============
; Clears both nametables and destroys all sprites.

        ClearDisplay:
        ldx     #$00            ; nametable 0
        jsr     FillNameTable
        ldx     #$01            ; nametable 1
        jsr     FillNameTable
        ldx     #$02            ; nametable 2
        jsr     FillNameTable
        jmp     DestroyAllSprites

; DestroyAllSprites
; =================

        DestroyAllSprites:
        ldx     #$00
        lda     #$F4
  @@10: sta     SPR_PosY,x     ; Set Y coord to below visible screen
        inx
        inx
        inx
        inx
        bne     @@10
        rts

; FillNameTable
; =============
; Fills name table with value BLANK_TILE. The corresponding attribute table
; is filled with 00s.
; X = name table # (0..3)

        FillNameTable:
        lda     ZPCtrl0
        and     #%11111011      ; PPU increment = 1
        sta     ZPCtrl0
        sta     PPUCtrl0
        txa                     ; A = nametable
        asl
        asl
        ora     #$20            ; high PPU address
        ldx     PPUStat         ; reset PPU address flip flop
        sta     PPUAddr
        lda     #$00
        sta     PPUAddr
        ldy     #$C0
        ldx     #$04
        lda     #BLANK_TILE     ; fill with this value
  @@10: sta     PPUIOReg
        dey
        bne     @@10
        dex
        bne     @@10
        ldy     #$40            ; attribute table size = $40 bytes
        txa                     ; A = 0
  @@20: sta     PPUIOReg
        dey
        bne     @@20
        rts

; WritePPUString
; ==============
; Writes a sequence of data strings to VRAM.
; pData: ptr to first string
; -------------
; String format:
; byte 0: high byte of PPU address
; byte 1: low byte of PPU address
; byte 2: bits 0-5 length of data string (repeat count if RLE)
;         bit 6 is data RLE? (1 = yes)
;         bit 7 PPU address increment (0 = 1, 1 = 32)
; byte 3-..: data. Only 1 byte if string is RLE
; -------------
; When byte 0 is zero, it means that no more strings remain to be written.

        ReallyWritePPUString:
        ldx     PPUStat         ; reset PPU address flip flop
        sta     PPUAddr         ; set PPU hi address
        pha                     ; save it for later
        iny
        lda     [pData],y
        sta     PPUAddr         ; set PPU lo address
        iny
        lda     [pData],y       ; string info byte
        asl                     ; CF = PPU address increment
        tax
        lda     ZPCtrl0
        ora     #%00000100
        bcs     @@40            ; if CF set, PPU inc = 32
        and     #%11111011      ; else PPU inc = 1
  @@40: sta     ZPCtrl0
        sta     PPUCtrl0
        txa
        asl                     ; CF = RLE status (1 = RLE)
        lda     [pData],y       ; string info byte again
        and     #$3F            ; data length in lower 6 bits
        tax                     ; use as loop counter
        bcc     @@PPUWriteLoop  ; branch if string isn't RLE
        iny
        lda     [pData],y       ; fetch the RLE data byte
        @@PPURepeatLoop:
        sta     PPUIOReg
        dex
        bne     @@PPURepeatLoop
        beq     @@50
        @@PPUWriteLoop:
        iny
        lda     [pData],y       ; fetch the next data byte
        sta     PPUIOReg        ; write to PPU
        dex
        bne     @@PPUWriteLoop
  @@50: pla                     ; restore PPU hi address
        cmp     #$3F            ; was the data written to page $3F?
        bne     @@60            ; branch if not
        sta     PPUAddr
        stx     PPUAddr
        stx     PPUAddr
        stx     PPUAddr
  @@60: tya                     ; A = string length - 1
        sec                     ; set carry, so we are adding actual strlen
        adc     pData           ; add to pointer
        sta     pData           ; pData now points to the next string
        bcc     WritePPUString
        inc     pData+1
        WritePPUString:
        ldy     #$00
        lda     [pData],y
        bne     ReallyWritePPUString            ; non-zero = valid string, write it
        ExitMe:
        rts

; CheckPPUWrite
; =============
; Writes any data waiting to be written to VRAM.

        CheckPPUWrite:
        ldy     PPUDataPending
        beq     ExitMe          ; exit if no data pending
        dey                     ; Y = 0
        sty     PPUStrIndex
        sty     PPUDataPending

	lda     #<PPUString
        sta     pData
        lda     #>PPUString
        sta     pData+1
        jmp     WritePPUString

; WriteROMPPUString
; =================
; In: A = low address.
;     Y = high address.

        WriteROMPPUString:
        sta     pData
        sty     pData+1
        jmp     WritePPUString

; EndPPUString
; ============

        EndPPUString:
        stx     PPUStrIndex
        lda     #$00
        sta     PPUString,x
        lda     #$01
        sta     PPUDataPending
        rts

; ReadJoypad0
; ===========
; Reads the status of all 8 buttons.
; Returns: JoyStat  = button status.
;          JoyFirst = only reports a button press the first time the
;                     button is pressed; not while it's being held down.

        ReadJoypad0:
        lda     JoyStat
        pha                     ; save last frame's status
        ldy     #$01
        sty     JoyReg          ; reset strobe
        dey
        sty     JoyReg          ; clear strobe
        ldy     #$08            ; do all 8 buttons
  @@10: lda     JoyReg          ; load button status
        lsr                     ; transfer to carry flag
        rol     JoyStat         ; rotate all bits left, put CF in bit 0
        dey                     ; done 8 buttons?
        bne     @@10            ; if not, do another
        pla                     ; last frame's button status
        eor     JoyStat
        and     JoyStat
        sta     JoyFirst
        rts

; ClearRAM
; ========

        ClearRAM:
        lda     #$00
        tax
  @@10: sta     $00,x
        sta     $0700,x
        inx
        bne     @@10
        rts

; GoRoutine
; =========
; Indirect jump routine.
; A: Routine # to execute
; A is used as an index into a table of code addresses.
; The jump table itself MUST be located directly after the JSR to this
; routine, so that its address can be popped from the stack.

        GoRoutine:
        asl                     ; each ptr is 2 bytes
        tay
        iny                     ; b/c stack holds jump table address MINUS 1
        pla                     ; low address of jump table
        sta     pCode
        pla                     ; high address of jump table
        sta     pCode+1
        lda     [pCode],y
        pha
        iny
        lda     [pCode],y
        pha
        rts                     ; jump to routine

; GoMainHandler
; =============

        GoMainHandler:
        lda     MainRoutine
        jsr     GoRoutine

.db >(TitleInit-1),     <(TitleInit-1)
.db >(TitleMain-1),     <(TitleMain-1)
.db >(GameInit-1),      <(GameInit-1)
.db >(LevelInit-1),     <(LevelInit-1)
.db >(LevelMain-1),     <(LevelMain-1)
.db >(PlayDemo-1),      <(PlayDemo-1)
.db >(GameOverInit-1),  <(GameOverInit-1)
.db >(GameOverMain-1),  <(GameOverMain-1)
.db >(TheEndInit-1),    <(TheEndInit-1)
.db >(TheEndMain-1),    <(TheEndMain-1)
.db >(DesignMenuInit-1),<(DesignMenuInit-1)
.db >(DesignMenuMain-1),<(DesignMenuMain-1)
.db >(DesignInit-1),    <(DesignInit-1)
.db >(DesignMain-1),    <(DesignMain-1)
.db >(PauseMain-1),     <(PauseMain-1)
.db >(ScoreMain-1),     <(ScoreMain-1)
.db >(NextLevel-1),     <(NextLevel-1)
.db >(WaitTimer-1),     <(WaitTimer-1)

; GameInit
; ========

        GameInit:
        lda     #2
        sta     LivesLeft
        lda     #0
        sta     Score
        sta     Score+1
        sta     Score+2
        lda     #mrLevelInit
        sta     MainRoutine
.ifdef DEMOREC
    ; prepare to record game demo
        lda     #$07
        sta     pDemo+1
        ldy     #0
        sty     pDemo   ; store demo in RAM, starting at $700.
        sty     OldStat
        iny     ; =1
        sty     JoyCount
.endif  ; DEMOREC
        rts

; LevelInit
; =========

        LevelInit:
        jsr     ScreenOff
        jsr     ClearDisplay
        lda     ZPCtrl0
        and     #$FC        ; select nametable 0
        sta     ZPCtrl0
        lda     #12
        sta     BombCelNum
; draw border and status bar
        lda     #<LevelBorderData
        ldy     #>LevelBorderData
        jsr     WriteROMPPUString
        lda     #<StatusBarData
        ldy     #>StatusBarData
        jsr     WriteROMPPUString
; load level palette
        jsr     SetLevelTheme
        lda     LevelTheme
        asl
        tax
        lda     LevelPalPtrTable,x
        ldy     LevelPalPtrTable+1,x
        jsr     PAL_LoadPalette
; load and render level
        jsr     SetLevelPtr
        jsr     RenderLevel
        jsr     PlaceBombs
; set initial # of reachable bombs
        lda     BombCount
        sta     BombsLeft
; set initial player position
        ldy     #9
        lda     [pLevel],y
        and     #$0F
        sta     GridY
        lda     [pLevel],y
        lsr
        lsr
        lsr
        lsr
        sta     GridX
        jsr     SetGridOfs
; init bomb timer
        lda     BombTimerReset
        sta     BombTimer
        lda     #29
        sta     BombTick
; print initial status bar data
        lda     #$23
        ldy     #$36
        jsr     PrintLevel
        jsr     PrintLives
        jsr     PrintScore
        jsr     PrintTopScore
        jsr     PrintBombTimer
        jsr     CheckPPUWrite   ; write immediately
;
        lda     #mrLevelMain
        ldy     DemoMode
        beq     @@10
        lda     #mrPlayDemo
  @@10: sta     MainRoutine
        jsr     LevelMain   ; just so objects are drawn during fade-in
        jsr     ScreenOn
        lda     #6
        sta     SFX_Number
        jmp     PAL_FadeFromBlack

; LevelMain
; ==========
; The game engine main loop.

        LevelMain:
.ifdef DEMOREC
        jsr     RecordDemo
.endif
        jsr     DestroyAllSprites
        lda     SpriteBase
        sta     SpriteIndex
        jsr     UpdateBombTimer
        jsr     UpdateJohnSolver
        jsr     DrawJohnSolver
        jsr     DrawBombs
        lda     SpriteBase
        clc
        adc     #17*4
        sta     SpriteBase
    ; check for pause/quit
        lda     JoyFirst
        and     #btnSTART
        beq     NoPause
        lda     JoyStat
        and     #btnSELECT
        beq     PauseGame
    ; abort level
        lda     DesignMode
        beq     TimeUp
        lda     #mrDesignMenuInit
        sta     MainRoutine
        jmp     PAL_FadeToBlack
    ; pause game
        PauseGame:
        lda     ZPCtrl1
        and     #%11101111      ; turn off sprites
        sta     ZPCtrl1
        lda     #7
        sta     SFX_Number
        lda     #mrPauseMain
        sta     MainRoutine
        NoPause:
        rts

        UpdateBombTimer:
        dec     BombTick
        bpl     LaterDude
        lda     #1
        sta     SFX_Number
        lda     #29
        sta     BombTick
        dec     BombTimer
        jsr     PrintBombTimer
        lda     BombTimer
        bne     LaterDude
        ; time up!
        TimeUp:
        inc     BombCelNum
        lda     #<BloodPal
        ldy     #>BloodPal
        jsr     PAL_LoadPalette
        jsr     PAL_SetPalette
        jsr     LevelMain
        lda     #8
        sta     SFX_Number
        lda     #60
        ldx     #mrLevelInit
        dec     LivesLeft
        bpl     @@20
        ldx     #mrGameOverInit
  @@20: jmp     SetTimer
        LaterDude:
        rts

        UpdateJohnSolver:
        lda     JoyFirst
        lsr
        bcc     @@10
        jmp     CheckMoveRight
  @@10: lsr
        bcc     @@20
        jmp     CheckMoveLeft
  @@20: lsr
        bcc     @@30
        jmp     CheckMoveDown
  @@30: lsr
        bcc     @@40
        jmp     CheckMoveUp
  @@40: rts

        LevelCompleted:
        lda     #5
        sta     SFX_Number
        lda     #7
        ldx     #mrScoreMain
        jmp     SetTimer

        NextLevel:
        ldy     #mrLevelInit
        lda     Level
        inc     Level
        cmp     #NUM_LEVELS
        bne     @@10
        ldy     #mrTheEndInit
  @@10: sty     MainRoutine
        jmp     PAL_FadeToBlack

        CheckMoveLeft:
        lda     #2
        sta     Temp
        ldy     GridOfs
        lda     $80,y
        cmp     #2     ; vertical wall in grid cell?
        bcc     @@10   ; branch if not, move OK
        ldx     GridX
        bne     @@20
        rts
  @@20: tax
        dey
        lda     $80,y
        cmp     #2    ; vertical wall in neighbour cell as well?
        bcc     @@30  ; if not, move the wall to that cell
        ; move NOT OK, vertical wall is blocking
        rts
  @@30: ora     #2  ; put in vertical wall
        sta     $80,y
        iny
        txa
        and     #1  ; remove vertical wall
        sta     $80,y
        ldx     GridX
        ldy     GridY
        jsr     EraseVerticalWall
        ldx     GridX
        dex
        jsr     DrawVerticalWall
        inc     Temp
    ; should check here if a bomb was just blocked...
    ; ...
  @@10: lda     GridX
        bne     @@40
        jmp     LevelCompleted
  @@40: dec     GridX
        jsr     SetGridOfs
        lda     Temp
        sta     SFX_Number
        jmp     NextFrame

        CheckMoveRight:
        lda     #2
        sta     Temp
        ldy     GridOfs
        iny
        lda     $80,y
        cmp     #2     ; vertical wall in next grid cell?
        bcc     @@10   ; branch if not, move OK
        ldx     GridX
        cpx     #5
        bne     @@20
        rts
  @@20: tax
        iny
        lda     $80,y
        cmp     #2  ; vertical wall in neighbour cell as well?
        bcc     @@30  ; if not, move the wall to that cell
        ; move NOT OK, vertical wall is blocking
        rts
  @@30: ora     #2  ; put in vertical wall
        sta     $80,y
        dey
        txa
        and     #1  ; remove vertical wall
        sta     $80,y
        ldx     GridX
        inx
        ldy     GridY
        jsr     EraseVerticalWall
        ldx     GridX
        inx
        inx
        jsr     DrawVerticalWall
        inc     Temp
    ; should check here if a bomb was just blocked...
    ; ...
  @@10: lda     GridX
        cmp     #5
        bne     @@40
        jmp     LevelCompleted
  @@40: inc     GridX
        jsr     SetGridOfs
        lda     Temp
        sta     SFX_Number
        jmp     NextFrame

        CheckMoveUp:
        lda     #2
        sta     Temp
        ldy     GridOfs
        lda     $80,y
        lsr         ; horizontal wall in grid cell?
        bcc     @@10   ; branch if not, move OK
        rol
        ldx     GridY
        bne     @@20
        rts
  @@20: tax
        tya
        sec
        sbc     #7
        tay
        lda     $80,y
        lsr         ; horizontal wall in neighbour cell as well?
        bcc     @@30  ; if not, move the wall to that cell
        ; move NOT OK, horizontal wall is blocking
        rts
  @@30: sec
        rol         ; put in horizontal wall
        sta     $80,y
        tya
        clc
        adc     #7
        tay
        txa
        and     #2  ; remove horizontal wall
        sta     $80,y
        ldx     GridX
        ldy     GridY
        jsr     EraseHorizontalWall
        ldx     GridX
        dey
        jsr     DrawHorizontalWall
        inc     Temp
    ; should check here if a bomb was just blocked...
    ; ...
  @@10: lda     GridY
        bne     @@40
        jmp     LevelCompleted
  @@40: dec     GridY
        jsr     SetGridOfs
        lda     Temp
        sta     SFX_Number
        jmp     NextFrame

        CheckMoveDown:
        lda     #2
        sta     Temp
        lda     GridOfs
        clc
        adc     #7
        tay
        lda     $80,y
        lsr         ; horizontal wall in next grid cell?
        bcc     @@10   ; branch if not, move OK
        rol
        ldx     GridY
        cpx     #3
        bne     @@20
        rts
  @@20: tax
        tya
        clc
        adc     #7
        tay
        lda     $80,y
        lsr         ; horizontal wall in neighbour cell as well?
        bcc     @@30  ; if not, move the wall to that cell
        ; move NOT OK, vertical wall is blocking
        rts
  @@30: sec
        rol         ; put in horizontal wall
        sta     $80,y
        tya
        sec
        sbc     #7
        tay
        txa
        and     #2  ; remove horizontal wall
        sta     $80,y
        ldx     GridX
        ldy     GridY
        iny
        jsr     EraseHorizontalWall
        ldx     GridX
        iny
        jsr     DrawHorizontalWall
        inc     Temp
    ; should check here if a bomb was just blocked...
    ; ...
  @@10: lda     GridY
        cmp     #3
        bne     @@40
        jmp     LevelCompleted
  @@40: inc     GridY
        jsr     SetGridOfs
        lda     Temp
        sta     SFX_Number
        jmp     NextFrame

        SetGridOfs:
        lda     #0
        ldy     GridY
        clc
  @@10: dey
        bmi     @@20
        adc     #7
        bcc     @@10
  @@20: adc     GridX
        sta     GridOfs
        rts

        NextFrame:
        inc     CelNum
        lda     CelNum
        cmp     #12
        bne     @@10
        lda     #0
        sta     CelNum
  @@10: rts

        DrawJohnSolver:
        lda     GridX
        asl
        asl
        asl
        asl
        asl
        clc
        adc     #44
        tax
        lda     GridY
        asl
        asl
        asl
        asl
        asl
        clc
        adc     #51
        tay
        lda     CelNum
        jmp     DrawCel

        DrawBombs:
        lda     BombCount
        beq     @@10
        lda     #0
  @@20: pha
        tay
        ldx     BombX,y
        lda     BombY,y
        tay
        lda     BombCelNum
        jsr     DrawCel
        pla
        clc
        adc     #1
        cmp     BombCount
        bne     @@20
  @@10: rts

        PlaceBombs:
    ; scan top row
        lda     #0
        sta     BombCount
  @@10: pha
        tay
        lda     $80,y
        lsr
        bcs     @@20
        tya
        asl
        asl
        asl
        asl
        asl
        adc     #44
        ldy     BombCount
        sta     BombX,y
        lda     #14
        sta     BombY,y
        inc     BombCount
  @@20: pla
        clc
        adc     #1
        cmp     #6
        bne     @@10
    ; scan bottom row
        lda     #0
  @@30: pha
        tay
        lda     $80+28,y
        lsr
        bcs     @@40
        lda     BombCount
        cmp     #8
        beq     @@40
        tya
        asl
        asl
        asl
        asl
        asl
        adc     #44
        ldy     BombCount
        sta     BombX,y
        lda     #182
        sta     BombY,y
        inc     BombCount
  @@40: pla
        clc
        adc     #1
        cmp     #6
        bne     @@30
    ; scan leftmost column
        lda     #0
  @@50: pha
        tay
        lda     $80,y
        and     #2
        bne     @@60
        lda     BombCount
        cmp     #8
        beq     @@60
        tya
        ldx     #0
        sec
  @@70: sbc     #7
        bmi     @@80
        inx
        bne     @@70
  @@80: txa
        asl
        asl
        asl
        asl
        asl
        adc     #51
        ldy     BombCount
        sta     BombY,y
        lda     #8
        sta     BombX,y
        inc     BombCount
  @@60: pla
        clc
        adc     #7
        cmp     #28
        bne     @@50
    ; scan rightmost column
        lda     #0
  @@90: pha
        tay
        lda     $80+6,y
        and     #2
        bne     @@100
        lda     BombCount
        cmp     #8
        beq     @@100
        tya
        ldx     #0
        sec
 @@110: sbc     #7
        bmi     @@120
        inx
        bne     @@110
 @@120: txa
        asl
        asl
        asl
        asl
        asl
        adc     #51
        ldy     BombCount
        sta     BombY,y
        lda     #240
        sta     BombX,y
        inc     BombCount
 @@100: pla
        clc
        adc     #7
        cmp     #28
        bne     @@90
        rts

        SetGridVRAMAddr:
        tya
        ora     #$40
        sta     pVRAM+1
        lda     #0
        sta     pVRAM
        lsr     pVRAM+1
        ror     pVRAM
        txa
        asl
        asl
        ora     pVRAM
        clc
        adc     #$83
        sta     pVRAM
        bcc     @@10
        inc     pVRAM+1
  @@10: rts

; DesignMenuInit
; ==============

        DesignMenuInit:
        jsr     ScreenOff
        jsr     ClearDisplay
        lda     #1
        sta     DesignMode
        lda     ZPCtrl0
        and     #$FC            ; nametable address = $2000
        sta     ZPCtrl0
        lda     #$00
        sta     pLevelData
        lda     #$03
        sta     pLevelData+1
        lda     #<DesignMenuData
        ldy     #>DesignMenuData
        jsr     WriteROMPPUString
        lda     #<TitlePal
        ldy     #>TitlePal
        jsr     PAL_LoadPalette
        lda     #4
        sta     MenuItems
        lda     #0
        sta     MenuSelect
        lda     #63
        sta     MenuCursorY
        lda     #64
        sta     MenuCursorX
        jsr     SetMenuCursor
        lda     #$21
        ldy     #$96
        jsr     PrintLevel
        jsr     CheckPPUWrite
        jsr     ScreenOn
        inc     MainRoutine
        jmp     PAL_FadeFromBlack

; DesignMenuMain
; ==============

        DesignMenuMain:
        lda     JoyFirst
        and     #btnSTART
        beq     @@10
        jsr     PAL_FadeToBlack
        ldy     MenuSelect
        bne     @@20
    ; play mode A
        lda     #50
        sta     BombTimerReset
        jmp     GameInit
  @@20: dey
        bne     @@30
    ; play mode B
        lda     #40
        sta     BombTimerReset
        jmp     GameInit
  @@30: dey
        bne     @@40
    ; design level X
        lda     #mrDesignInit
        sta     MainRoutine
        rts
    ; exit
  @@40: lda     #mrTitleInit
        sta     MainRoutine
        rts
  @@10: jsr     CheckLevelChange
        jsr     MenuHandler
        jmp     SetMenuCursor

; DesignInit
; ==========

        DesignInit:
        jsr     ScreenOff
        jsr     ClearDisplay
        lda     #<LevelBorderData
        ldy     #>LevelBorderData
        jsr     WriteROMPPUString
        jsr     SetLevelTheme
        lda     LevelTheme
        asl
        tax
        lda     LevelPalPtrTable,x
        ldy     LevelPalPtrTable+1,x
        jsr     PAL_LoadPalette
        jsr     SetLevelPtr
        jsr     RenderLevel
        jsr     PlaceBombs
        lda     #12
        sta     BombCelNum
        ldy     #9
        lda     [pLevel],y
        and     #$0F
        sta     GridY
        lda     [pLevel],y
        lsr
        lsr
        lsr
        lsr
        sta     GridX
        jsr     SetGridOfs
        inc     MainRoutine
        jsr     DesignMain
        jsr     ScreenOn
        jmp     PAL_FadeFromBlack

; DesignMain
; ==========

        DesignMain:
        jsr     DestroyAllSprites
        lda     SpriteBase
        sta     SpriteIndex
        jsr     CheckDesignButtons
        jsr     DrawJohnSolver
        jsr     DrawBombs
        lda     SpriteBase
        clc
        adc     #17*4
        sta     SpriteBase
        rts

        CheckDesignButtons:
        lda     JoyFirst
        lsr
        bcs     DesignMoveRight
        lsr
        bcs     DesignMoveLeft
        lsr
        bcs     DesignMoveDown
        lsr
        bcs     DesignMoveUp
        lsr
        bcs     DesignPushStart
        lsr
        bcs     DesignPushSelect
        lsr
        bcs     DesignPushB
        lsr
        bcs     DesignPushA
        rts

        DesignMoveRight:
        lda     GridX
        cmp     #6
        beq     @@10
        cmp     #5
        bne     @@20
        lda     GridY
        cmp     #4
        beq     @@10
  @@20: inc     GridX
        jsr     SetGridOfs
        jmp     NextFrame
  @@10: rts

        DesignMoveLeft:
        lda     GridX
        beq     @@10
        dec     GridX
        jsr     SetGridOfs
        jmp     NextFrame
  @@10: rts

        DesignMoveDown:
        lda     GridY
        cmp     #4
        beq     @@10
        cmp     #3
        bne     @@20
        lda     GridX
        cmp     #6
        beq     @@10
  @@20: inc     GridY
        jsr     SetGridOfs
        jmp     NextFrame
  @@10: rts

        DesignMoveUp:
        lda     GridY
        beq     @@10
        dec     GridY
        jsr     SetGridOfs
        jmp     NextFrame
  @@10: rts

        DesignPushStart:
        jsr     EncodeDesignLevel
        lda     #mrDesignMenuInit
        sta     MainRoutine
        jmp     PAL_FadeToBlack

        DesignPushSelect:
        rts

        DesignPushB:
        lda     GridY
        cmp     #4
        bne     @@10
        rts
  @@10: ldy     GridOfs
        lda     $80,y
        eor     #2      ; toggle vertical wall
        sta     $80,y
        ldx     GridX
        ldy     GridY
        and     #2
        beq     @@20
        jsr     DrawVerticalWall
        jmp     PlaceBombs
  @@20: jsr     EraseVerticalWall
        jmp     PlaceBombs

        DesignPushA:
        lda     GridX
        cmp     #6
        bne     @@10
        rts
  @@10: ldy     GridOfs
        lda     $80,y
        eor     #1      ; toggle horizontal wall
        sta     $80,y
        ldx     GridX
        ldy     GridY
        lsr
        bcc     @@20
        jsr     DrawHorizontalWall
        jmp     PlaceBombs
  @@20: jsr     EraseHorizontalWall
        jmp     PlaceBombs

        EncodeDesignLevel:
        ldx     #0
        ldy     #0
    ; encode playfield
  @@10: lda     $80,x
        sta     LevelByte
        lda     $80+1,x
        asl
        asl
        ora     LevelByte
        sta     LevelByte
        lda     $80+2,x
        asl
        asl
        asl
        asl
        ora     LevelByte
        sta     LevelByte
        lda     $80+3,x
        ror
        ror
        ror
        and     #$C0
        ora     LevelByte
        sta     [pLevel],y
        iny
        inx
        inx
        inx
        inx
        cpx     #36
        bne     @@10
    ; encode initial player position
        lda     GridX
        asl
        asl
        asl
        asl
        ora     GridY
        sta     [pLevel],y
        ExitAgain:
        rts

        ScoreMain:
        lda     FrameCount
        and     #3
        bne     ExitAgain
    ; make sure score doesn't exceed 999900 points
        lda     Score
        sec
        sbc     #$DC
        lda     Score+1
        sbc     #$41
        lda     Score+2
        sbc     #$0F
        bcs     @@10
    ; add 100 points to score
        lda     Score
        clc
        adc     #100
        sta     Score
        bcc     @@20
        inc     Score+1
        bne     @@20
        inc     Score+2
   @@20: lda     #4
        sta     SFX_Number
        jsr     PrintScore
    ; check if score exceeds top score
        lda     TopScore
        sec
        sbc     Score
        lda     TopScore+1
        sbc     Score+1
        lda     TopScore+2
        sbc     Score+2
        bcs     @@30
    ; new top score
        lda     Score
        sta     TopScore
        lda     Score+1
        sta     TopScore+1
        lda     Score+2
        sta     TopScore+2
        jsr     PrintTopScore
    ; check if an extra life should be given (50000 points)
  @@30: lda     Score
        cmp     #$50
        bne     @@40
        lda     Score+1
        cmp     #$C3
        bne     @@40
        lda     Score+2
        bne     @@40
    ; award extra life
        inc     LivesLeft
        jsr     PrintLives
        lda     #10
        ldx     #mrScoreMain
        jsr     SetTimer
        lda     #7
        sta     SFX_Number
    ; update timer
  @@40: dec     BombTimer
        jsr     PrintBombTimer
        lda     BombTimer
        bne     ExitAgain
    ; done adding points
  @@10: jsr     WaitNMIPass
        lda     #5
        ldx     #mrNextLevel
        ldy     DesignMode
        beq     @@50
        ldx     #mrDesignMenuInit
  @@50: jmp     SetTimer

        PauseMain:
        lda     JoyFirst
        and     #btnSTART
        beq     @@10
        lda     ZPCtrl1
        ora     #%00010000      ; turn on sprites again
        sta     ZPCtrl1
        lda     #mrLevelMain
        sta     MainRoutine
  @@10: rts

; WaitTimer
; =========
; Waits for Timer to hit zero, then updates MainRoutine.
; Basically just delays the program for a certain amount of time.

        WaitTimer:
        lda     Timer
        bne     @@10
        lda     NextRoutine
        sta     MainRoutine
        cmp     #mrGameOverInit
        beq     @@20
        cmp     #mrLevelInit
        beq     @@20
        cmp     #mrDesignMenuInit
        beq     @@20
        rts
  @@20: jmp     PAL_FadeToBlack
  @@10: rts

; SetTimer
; ========
; In: A = # of time units to delay
;     X = next routine to execute after delay

        SetTimer:
        sta     Timer
        stx     NextRoutine
        lda     #mrWaitTimer
        sta     MainRoutine
        rts

; RecordDemo
; ==========
; Records a game demo, by storing keypresses in RAM for each CPU frame.
; Data is realtime RLE encoded, two bytes per entry: 1st byte is the key
; state itself, 2nd byte is the number of frames that key state has been used.
; Call every frame in the game loop.
; pDemo must point to a valid RAM address where the demo can be stored.

pDemo       EQU     $75
OldStat     EQU     $77
JoyCount    EQU     $78

        RecordDemo:
        lda     OldStat
        cmp     JoyStat
        bne     IsNewStat       ; joy status has changed

        inc     JoyCount
        beq     IsNewStat       ; max. 256 repeats of a certain status
        rts

        IsNewStat:
        ldy     #$00
        sta     [pDemo],y       ; record joy status
        inc     pDemo
        bne     @@10
        inc     pDemo+1
  @@10: lda     JoyCount
        sta     [pDemo],y       ; record # of frames to use status
        inc     pDemo
        bne     @@20
        inc     pDemo+1
  @@20: lda     JoyStat
        sta     OldStat
        iny     ; =1
        sty     JoyCount
        rts

; PlayDemo
; ========
; Plays a demo.
; pDemo must point to valid key data, stored in the format described above.

        PlayDemo:
        lda     JoyFirst
        bne     StopDemo        ; user pressed a button, stop demo

        dec     JoyCount
        beq     NextStat

        sta     JoyFirst        ; =0, only non-zero 1st frame of each stat
        lda     OldStat
        sta     JoyStat         ; use same stat as last frame
        jmp     LevelMain      ; run the real game engine

        StopDemo:
        jsr     PAL_FadeToBlack
        lda     #mrTitleInit    ; return to title screen
        sta     MainRoutine
        rts

        NextStat:
        ldy     #$00
        lda     [pDemo],y
        cmp     #$FF            ; reached end of demo?
        beq     StopDemo
        sta     OldStat
        sta     JoyStat
        sta     JoyFirst
        inc     pDemo
        bne     @@10
        inc     pDemo+1
  @@10: lda     [pDemo],y
        sta     JoyCount
        inc     pDemo
        bne     @@20
        inc     pDemo+1
  @@20: jmp     LevelMain

        TheEndInit:
        jsr     ScreenOff
        jsr     ClearDisplay
        lda     ZPCtrl0
        and     #$FC        ; select nametable 0
        sta     ZPCtrl0
        lda     #0
        sta     ScrollX
        sta     ScrollY
        lda     #20
        sta     Timer
; load screen data
        lda     #<TheEndData
        ldy     #>TheEndData
        jsr     WriteROMPPUString
; load palette
        lda     #<TitlePal
        ldy     #>TitlePal
        jsr     PAL_LoadPalette
        inc     MainRoutine
        jsr     ScreenOn
        jmp     PAL_FadeFromBlack

        TheEndMain:
        lda     Timer
        bne     @@10
        lda     #mrTitleInit
        sta     MainRoutine
        jmp     PAL_FadeToBlack
  @@10: rts

; GameOverInit
; ============

        GameOverInit:
        jsr     ScreenOff
        jsr     ClearDisplay
        lda     #0
        sta     ScrollX
        sta     ScrollY
        sta     MenuSelect
        lda     ZPCtrl0
        and     #$FC        ; select nametable 0
        sta     ZPCtrl0
        lda     #40
        sta     Timer
    ; load game over screen
        lda     #<GameOverData
        ldy     #>GameOverData
        jsr     WriteROMPPUString
        lda     #<GameOverPal
        ldy     #>GameOverPal
        jsr     PAL_LoadPalette
    ;
        inc     MainRoutine
        jsr     ScreenOn
        lda     #9
        sta     SFX_Number
        jmp     PAL_FadeFromBlack

; GameOverMain
; ============

        GameOverMain:
        lda     Timer
        bne     @@10
        lda     #mrTitleInit
        ldy     DesignMode
        beq     @@20
        lda     #mrDesignMenuInit
  @@20: sta     MainRoutine
        jmp     PAL_FadeToBlack
  @@10: rts

;------------------------[ Non Maskable Interrupt ]---------------------------

        NMI:
        pha                     ; preserve A
        txa
        pha                     ; preserve X
        tya
        pha                     ; preserve Y

        ldy     FrameStat
        bne     @@10            ; skip the next part if the frame couldn't
                                ; finish before the NMI was triggered
        iny
        sty     FrameStat
        inc     FrameCount
        jsr     CheckPPUWrite
    ; update PPU control registers
        lda     ZPCtrl0
        sta     PPUCtrl0
        lda     ZPCtrl1
        sta     PPUCtrl1
    ; update scroll registers
        lda     PPUStat         ; reset H/V scroll flip flop
        lda     ScrollX
        sta     PPUScroll
        lda     ScrollY
        sta     PPUScroll
    ; perform sprite DMA
        lda     #$00
        sta     SPRAddr         ; reset SPR-RAM address
        lda     #$02
        sta     SPRDMAReg
    ; read da friggin joypad
        jsr     ReadJoypad0
    ; update music
        jsr     RNME_PlaySong
  @@10: pla
        tay                     ; restore Y
        pla
        tax                     ; restore X
        pla                     ; restore A
        rti

;-----------------------------------[ IRQ ]-----------------------------------

        IRQ:
        jmp     RESET

;----------------------------------[ Data ]-----------------------------------

TemplateLevel:
.db $57,$A5,$00,$28,$00,$0A,$80,$55,$05,$00

LevelPalPtrTable:
.dw LevelPal0
.dw LevelPal1
.dw LevelPal2
.dw LevelPal3
.dw LevelPal4
.dw LevelPal5
.dw LevelPal6
.dw LevelPal7
.dw LevelPal8
.dw LevelPal9

LevelPal0:
.db $0F,$17,$27,$30
.db $0F,$11,$02,$10
.db $0F,$30,$24,$2A
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$20,$31
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
LevelPal1:
.db $0F,$11,$21,$30
.db $0F,$15,$05,$10
.db $0F,$30,$24,$2A
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$20,$31
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
LevelPal2:
.db $0F,$18,$28,$30
.db $0F,$1C,$0C,$10
.db $0F,$30,$24,$2A
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$20,$31
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
LevelPal3:
.db $0F,$19,$29,$30
.db $0F,$14,$04,$10
.db $0F,$30,$24,$2A
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$20,$31
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
LevelPal4:
.db $0F,$00,$10,$30
.db $0F,$26,$16,$10
.db $0F,$30,$24,$2A
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$20,$31
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
LevelPal5:
.db $0F,$13,$23,$30
.db $0F,$19,$09,$10
.db $0F,$30,$24,$2A
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$20,$31
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
LevelPal6:
.db $0F,$14,$24,$30
.db $0F,$20,$00,$10
.db $0F,$30,$24,$2A
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$20,$31
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
LevelPal7:
.db $0F,$12,$22,$30
.db $0F,$27,$17,$10
.db $0F,$30,$24,$2A
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$20,$31
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
LevelPal8:
.db $0F,$15,$25,$30
.db $0F,$22,$12,$10
.db $0F,$30,$24,$2A
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$20,$31
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
LevelPal9:
.db $0F,$1C,$2C,$30
.db $0F,$13,$03,$10
.db $0F,$30,$24,$2A
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$20,$31
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
BloodPal:
.db $0F,$26,$16,$06
.db $0F,$06,$26,$16
.db $0F,$06,$26,$16
.db $0F,$0F,$0F,$0F
.db $0F,$36,$06,$16
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F

GameA_LevelData:
.incbin "levels/lvl1a.dat"
.incbin "levels/lvl2a.dat"
.incbin "levels/lvl3a.dat"
.incbin "levels/lvl4a.dat"
.incbin "levels/lvl5a.dat"
.incbin "levels/lvl6a.dat"
.incbin "levels/lvl7a.dat"
.incbin "levels/lvl8a.dat"
.incbin "levels/lvl9a.dat"
.incbin "levels/lvl10a.dat"
.incbin "levels/lvl11a.dat"
.incbin "levels/lvl12a.dat"
.incbin "levels/lvl13a.dat"
.incbin "levels/lvl14a.dat"
.incbin "levels/lvl15a.dat"
.incbin "levels/lvl16a.dat"
.incbin "levels/lvl17a.dat"
.incbin "levels/lvl18a.dat"
.incbin "levels/lvl19a.dat"
.incbin "levels/lvl20a.dat"
.incbin "levels/mylvls1.dat"
.incbin "levels/mylvls1.dat"
.incbin "levels/mylvls1.dat"

GameB_LevelData:
.incbin "levels/lvl1b.dat"
.incbin "levels/lvl2b.dat"
.incbin "levels/lvl3b.dat"
.incbin "levels/lvl4b.dat"
.incbin "levels/lvl5b.dat"
.incbin "levels/lvl6b.dat"
.incbin "levels/mylvls1.dat"
.incbin "levels/mylvls1.dat"
.incbin "levels/mylvls1.dat"
.incbin "levels/mylvls1.dat"

CelPtrTable:
.dw JohnSolverCel0
.dw JohnSolverCel1
.dw JohnSolverCel2
.dw JohnSolverCel3
.dw JohnSolverCel4
.dw JohnSolverCel5
.dw JohnSolverCel6
.dw JohnSolverCel7
.dw JohnSolverCel8
.dw JohnSolverCel9
.dw JohnSolverCel10
.dw JohnSolverCel11
.dw BombCel
.dw BombExplodeCel

JohnSolverCel0:
.db 9
.db $F4,$00,$00,$F4
.db $F4,$01,$00,$FC
.db $F4,$02,$00,$04
.db $FC,$10,$00,$F4
.db $FC,$11,$00,$FC
.db $FC,$12,$00,$04
.db $04,$20,$00,$F4
.db $04,$21,$00,$FC
.db $04,$22,$00,$04
JohnSolverCel1:
.db 9
.db $F4,$03,$00,$F4
.db $F4,$04,$00,$FC
.db $F4,$05,$00,$04
.db $FC,$13,$00,$F4
.db $FC,$14,$00,$FC
.db $FC,$15,$00,$04
.db $04,$23,$00,$F4
.db $04,$24,$00,$FC
.db $04,$25,$00,$04
JohnSolverCel2:
.db 9
.db $F4,$06,$00,$F4
.db $F4,$07,$00,$FC
.db $F4,$08,$00,$04
.db $FC,$16,$00,$F4
.db $FC,$17,$00,$FC
.db $FC,$18,$00,$04
.db $04,$26,$00,$F4
.db $04,$27,$00,$FC
.db $04,$28,$00,$04
JohnSolverCel3:
.db 9
.db $F4,$09,$00,$F4
.db $F4,$0A,$00,$FC
.db $F4,$0B,$00,$04
.db $FC,$19,$00,$F4
.db $FC,$1A,$00,$FC
.db $FC,$1B,$00,$04
.db $04,$29,$00,$F4
.db $04,$2A,$00,$FC
.db $04,$2B,$00,$04
JohnSolverCel4:
.db 9
.db $F4,$0C,$00,$F4
.db $F4,$0D,$00,$FC
.db $F4,$0E,$00,$04
.db $FC,$1C,$00,$F4
.db $FC,$1D,$00,$FC
.db $FC,$1E,$00,$04
.db $04,$2C,$00,$F4
.db $04,$2D,$00,$FC
.db $04,$2E,$00,$04
JohnSolverCel5:
.db 9
.db $F4,$30,$00,$F4
.db $F4,$31,$00,$FC
.db $F4,$32,$00,$04
.db $FC,$40,$00,$F4
.db $FC,$41,$00,$FC
.db $FC,$42,$00,$04
.db $04,$50,$00,$F4
.db $04,$51,$00,$FC
.db $04,$52,$00,$04
JohnSolverCel6:
.db 9
.db $F4,$33,$00,$F4
.db $F4,$34,$00,$FC
.db $F4,$35,$00,$04
.db $FC,$43,$00,$F4
.db $FC,$44,$00,$FC
.db $FC,$45,$00,$04
.db $04,$53,$00,$F4
.db $04,$54,$00,$FC
.db $04,$55,$00,$04
JohnSolverCel7:
.db 9
.db $F4,$36,$00,$F4
.db $F4,$37,$00,$FC
.db $F4,$38,$00,$04
.db $FC,$46,$00,$F4
.db $FC,$47,$00,$FC
.db $FC,$48,$00,$04
.db $04,$56,$00,$F4
.db $04,$57,$00,$FC
.db $04,$58,$00,$04
JohnSolverCel8:
.db 9
.db $F4,$39,$00,$F4
.db $F4,$3A,$00,$FC
.db $F4,$3B,$00,$04
.db $FC,$49,$00,$F4
.db $FC,$4A,$00,$FC
.db $FC,$4B,$00,$04
.db $04,$59,$00,$F4
.db $04,$5A,$00,$FC
.db $04,$5B,$00,$04
JohnSolverCel9:
.db 9
.db $F4,$3C,$00,$F4
.db $F4,$3D,$00,$FC
.db $F4,$3E,$00,$04
.db $FC,$4C,$00,$F4
.db $FC,$4D,$00,$FC
.db $FC,$4E,$00,$04
.db $04,$5C,$00,$F4
.db $04,$5D,$00,$FC
.db $04,$5E,$00,$04
JohnSolverCel10:
.db 9
.db $F4,$60,$00,$F4
.db $F4,$61,$00,$FC
.db $F4,$62,$00,$04
.db $FC,$70,$00,$F4
.db $FC,$71,$00,$FC
.db $FC,$72,$00,$04
.db $04,$80,$00,$F4
.db $04,$81,$00,$FC
.db $04,$82,$00,$04
JohnSolverCel11:
.db 9
.db $F4,$63,$00,$F4
.db $F4,$64,$00,$FC
.db $F4,$65,$00,$04
.db $FC,$73,$00,$F4
.db $FC,$74,$00,$FC
.db $FC,$75,$00,$04
.db $04,$83,$00,$F4
.db $04,$84,$00,$FC
.db $04,$85,$00,$04

BombCel:
.db 4
.db $F8,$66,$00,$F8
.db $F8,$67,$00,$00
.db $00,$76,$00,$F8
.db $00,$77,$00,$00
BombExplodeCel:
.db 4
.db $F8,$6D,$00,$F8
.db $F8,$6E,$00,$00
.db $00,$7D,$00,$F8
.db $00,$7E,$00,$00

LevelBorderData:
; upper border
.db $20,$20,$1F,$20,$21,$08,$09,$08,$09,$08,$09,$08,$09,$08,$09,$08,$09,$08,$09,$08,$09,$08,$09,$08,$09,$08,$09,$08,$09,$08,$09,$08,$22,$23
.db $20,$40,$1F,$30,$31,$18,$19,$18,$19,$18,$19,$18,$19,$18,$19,$18,$19,$18,$19,$18,$19,$18,$19,$18,$19,$18,$19,$18,$19,$18,$19,$18,$32,$33
.db $23,$C0,$48,$55
; lower border
.db $22,$C0,$1F,$24,$25,$0A,$0B,$0A,$0B,$0A,$0B,$0A,$0B,$0A,$0B,$0A,$0B,$0A,$0B,$0A,$0B,$0A,$0B,$0A,$0B,$0A,$0B,$0A,$0B,$0A,$0B,$0A,$26,$27
.db $22,$E0,$1F,$34,$35,$1A,$1B,$1A,$1B,$1A,$1B,$1A,$1B,$1A,$1B,$1A,$1B,$1A,$1B,$1A,$1B,$1A,$1B,$1A,$1B,$1A,$1B,$1A,$1B,$1A,$1B,$1A,$36,$37
.db $23,$E8,$01,$51,$23,$E9,$46,$50,$23,$EF,$01,$55
; left border
.db $20,$60,$93,$0C,$1C,$0C,$1C,$0C,$1C,$0C,$1C,$0C,$1C,$0C,$1C,$0C,$1C,$0C,$1C,$0C,$1C,$0C
.db $20,$61,$93,$0D,$1D,$0D,$1D,$0D,$1D,$0D,$1D,$0D,$1D,$0D,$1D,$0D,$1D,$0D,$1D,$0D,$1D,$0D
.db $23,$C8,$01,$11,$23,$D0,$01,$11,$23,$D8,$01,$11,$23,$E0,$01,$11
; right border
.db $20,$7D,$93,$0E,$1E,$0E,$1E,$0E,$1E,$0E,$1E,$0E,$1E,$0E,$1E,$0E,$1E,$0E,$1E,$0E,$1E,$0E
.db $20,$7E,$93,$0F,$1F,$0F,$1F,$0F,$1F,$0F,$1F,$0F,$1F,$0F,$1F,$0F,$1F,$0F,$1F,$0F,$1F,$0F
.db $23,$CF,$01,$55,$23,$D7,$01,$55,$23,$DF,$01,$55,$23,$E7,$01,$55
; inner border
.db $20,$62,$01,$14,$20,$63,$59,$12,$20,$7C,$01,$15
.db $22,$A2,$01,$11,$22,$A3,$59,$12,$22,$BC,$01,$13
.db $20,$82,$D1,$16
.db $20,$9C,$D1,$16
.db 0

StatusBarData:
.db $23,$21,$01,$A1 ; I-
.db $23,$29,$03,$A2,$A3,$A4 ; TOP-
.db $23,$33,$06,$A5,$E5,$FE,$D0,$D0,$A6 ; L=
.db $23,$39,$06,$A5,$ED,$E2,$E6,$DE,$a6 ; TIME
.db $23,$53,$06,$A7,$E3,$FE,$00,$D0,$A8 ; J=
.db $23,$59,$06,$A7,$D0,$D0,$D0,$D0,$A8 ;
.db $23,$F0,$50,$AA
.db 0

TitleData:
; BOMBSWEEPER logo
.db $20,$E5,$18,$B0,$B1,$BE,$BF,$B2,$B3,$B0,$B1,$00,$B4,$B5,$B6,$B7,$B8,$B9,$B8,$B9,$BA,$BB,$B8,$B9,$BC,$BD,$FD
.db $21,$05,$17,$C0,$C1,$CE,$CF,$C2,$C3,$C0,$C1,$00,$C4,$C5,$C6,$C7,$C8,$C9,$C8,$C9,$CA,$CB,$C8,$C9,$CC,$CD
.db $23,$C0,$58,$55
; menu
.db $21,$8D,$06
.asc "GAME A"
.db $21,$CD,$06
.asc "GAME B"
.db $22,$0D,$06
.asc "DESIGN"
.db $23,$D8,$50,$AA
; game info
.db $22,$85,$17
.db $FC : .asc " 2002 SNOWBRO SOFTWARE"
.db $22,$C9,$0E
.asc "MADE IN NORWAY"
.db 0

; design menu
DesignMenuData:
; title
.db $20,$6A,$0C
.asc "LEVEL DESIGN"
; border
.db $20,$C6,$01,$14
.db $20,$C7,$52,$12
.db $20,$D9,$01,$15
.db $20,$E6,$C9,$16
.db $20,$F9,$C9,$16
.db $22,$06,$01,$11
.db $22,$07,$52,$12
.db $22,$19,$01,$13
; menu
.db $21,$0A,$0B
.asc "PLAY MODE A"
.db $21,$4A,$0B
.asc "PLAY MODE B"
.db $21,$8A,$0B
.asc "EDIT  LEVEL"
.db $21,$CA,$04
.asc "EXIT"
.db $23,$D2,$44,$FF
.db $23,$DD,$01,$08
.db 0

TitlePal:
.db $0F,$20,$0F,$0F
.db $0F,$2A,$11,$20
.db $0F,$15,$0F,$0F
.db $0F,$28,$0F,$0F
.db $0F,$2C,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F
.db $0F,$0F,$0F,$0F

TheEndData:
.db $21,$C8,$10
.asc "CONGRATULATIONS!"
.db 0

GameOverData:
.db $21,$CC,$09
.asc "GAME OVER"
.db 0

GameOverPal:
.db $0F,$20,$20,$20
.db $0F,$20,$20,$20
.db $0F,$20,$20,$20
.db $0F,$20,$20,$20
.db $0F,$20,$20,$20
.db $0F,$20,$20,$20
.db $0F,$20,$20,$20
.db $0F,$20,$20,$20

BitMaskTable:
.db %00000001
.db %00000010
.db %00000100
.db %00001000
.db %00010000
.db %00100000
.db %01000000
.db %10000000

GameDemos:
.dw demo1
.dw demo2
.dw demo3
.dw demo4

demo1:
.incbin "demos/demo1.dat"
demo2:
.incbin "demos/demo2.dat"
demo3:
.incbin "demos/demo3.dat"
demo4:
.incbin "demos/demo4.dat"

DemoLevels:
.db 1,6,12,16

ButtonCombo:
.db btnLEFT,btnLEFT,btnRIGHT,btnRIGHT
.db btnA,btnB,btnA,btnB

.end
