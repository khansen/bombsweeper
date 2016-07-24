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

; -------------------------------[ Defines ]----------------------------------

; global variables

RNME_pSong              EQU     $C0
RNME_pPattern           EQU     $C2
RNME_pOrder             EQU     $C4
RNME_pEnvelope          EQU     $C6
RNME_pPatPtrTable       EQU     $C8
RNME_Status             EQU     $CA
RNME_LoadTune           EQU     $CB
RNME_Trigger            EQU     $CC
RNME_LastTune           EQU     $CD
RNME_SFXStatus          EQU     $CE
RNME_pSFX               EQU     $D0

; general channel variables

CHN_OrderPos            EQU     $0700
CHN_Pattern             EQU     $0705
CHN_PatPos              EQU     $070A
CHN_Row                 EQU     $070F
CHN_EndRow              EQU     $0714
CHN_RowStatus           EQU     $0719
CHN_PatLoopCount        EQU     $071E
CHN_Speed               EQU     $0723
CHN_Tick                EQU     $0728
CHN_Transpose           EQU     $072D
CHN_pPatternLo          EQU     $0732
CHN_pPatternHi          EQU     $0737
CHN_pOrderLo            EQU     $073C
CHN_pOrderHi            EQU     $0741
CHN_OrderRepPos         EQU     $0746
CHN_OrderRepCount       EQU     $074B

; chn0-2 only

CHN_Note                EQU     $0756
CHN_FreqHi              EQU     $0759
CHN_ResVib              EQU     $075C
CHN_VibDelay            EQU     $075F
CHN_VibratoPos          EQU     $0762
CHN_SlFreqLo            EQU     $0765
CHN_SlFreqHi            EQU     $0768
CHN_Effect              EQU     $076B
CHN_EffParam            EQU     $076E
CHN_EffInfo             EQU     $0771

; volume envelope info (chn0-3 only)

ENV_Index               EQU     $077C
ENV_StepLo              EQU     $0780
ENV_StepHi              EQU     $0784
ENV_Fraction            EQU     $0788
ENV_CurrentVol          EQU     $078C
ENV_DestVol             EQU     $0790
ENV_pLopeLo             EQU     $0794
ENV_pLopeHi             EQU     $0798
ENV_HoldLength          EQU     $079C
ENV_WaveInfo            EQU     $07A0
ENV_Phase               EQU     $07A4
ENV_MasterVol           EQU     $07A8

; RAM copies of channel regs (chn0-3 only)

CHN_Reg0                EQU     $07AC
CHN_Reg1                EQU     $07B0
CHN_Reg2                EQU     $07B4
CHN_Reg3                EQU     $07B8
CHN_OldReg0             EQU     $07BC
CHN_OldReg1             EQU     $07C0
CHN_OldReg2             EQU     $07C4
CHN_OldReg3             EQU     $07C8

SQR_DutyDelay           EQU     $07CC
SQR_DutyCycle           EQU     $07CE

; sfx info

SFX_Number              EQU     $07D0
SFX_pDataHi             EQU     $07D5
SFX_pDataLo             EQU     $07DA
SFX_Index               EQU     $07DF
SFX_HoldLength          EQU     $07E4

; ---------------------------------[ Code ]-----------------------------------

;-----------------------------------------------------------------------------
; RNME_InitSong - call once per song
;-----------------------------------------------------------------------------

        RNME_InitSong:
; set up pointer to song data
        asl
        tax
        lda     RNME_SongPtrTable,x
        sta     RNME_pSong
        lda     RNME_SongPtrTable+1,x
        sta     RNME_pSong+1

; clear out entire music RAM
        lda     #0
        tay
  @@10: sta     $700,y
        iny
        bne     @@10

; set up ptr to order table for each channel
; initialize some other variables
        ldy     #$00                    ; reset header index
        ldx     #$00                    ; start with channel 0
        RNME_InitChannel:
        inc     CHN_PatLoopCount,x  ; =1
        inc     CHN_EndRow,x    ; =1
        lda     [RNME_pSong],y
        sta     CHN_pOrderLo,x
        iny
        lda     [RNME_pSong],y
        sta     CHN_pOrderHi,x
        iny
        lda     [RNME_pSong],y
        sta     CHN_Speed,x
        sta     CHN_Tick,x
        dec     CHN_Tick,x              ; Tick = Speed - 1
        iny
        inx                             ; next channel
        cpx     #$02                    ; done all channels yet (0..4)?
        bne     RNME_InitChannel

; get pointer to song's pattern pointer table
        lda     [RNME_pSong],y
        sta     RNME_pPatPtrTable
        iny
        lda     [RNME_pSong],y
        sta     RNME_pPatPtrTable+1

; init some sound regs
        ldx     #$01
  @@10: lda     #$08
        sta     CHN_Reg1,x
        sta     CHN_Reg3,x
        lda     #$F0
        sta     ENV_MasterVol,x
        dex
        bpl     @@10
; force all channels to be updated 1st time player is called
        lda     #$03
        sta     RNME_Trigger

; enable channels 0-3 (chn 4 must be enabled at each sample trigger)
        lda     #%00000011
        sta     $4015

; set the "music = playing" flag
        lda     #$01
        sta     RNME_Status
        rts

;-----------------------------------------------------------------------------
; RNME_PlaySong - call every NMI
;-----------------------------------------------------------------------------

        RNME_PlaySong:
        ldy     RNME_LoadTune
        beq     RNME_NoNewSong
; Y contains the song to start playing, plus 1
        sty     RNME_LastTune
        lda     #$00
        sta     RNME_LoadTune
        dey
        tya
        jmp     RNME_InitSong

        RNME_NoNewSong:
        lda     RNME_Status
        bne     @@10
        rts                      ; exit if no song is playing
        @@10:
        ldx     #$01                    ; channel loop counter
        RNME_ChannelLoop:
;;;;;;;;;;;;;   BEGIN SFX CODE
; check for new sfx
        ldy     SFX_Number,x
        beq     RNME_NoSFXTrigger
; load sfx
        dey
        tya
        asl
        tay
        lda     RNME_SFXPtrTable,y
        sta     SFX_pDataLo,x
        iny
        lda     RNME_SFXPtrTable,y
        sta     SFX_pDataHi,x
        lda     #$00
        sta     SFX_Number,x
        sta     SFX_Index,x
        lda     #$01
        sta     SFX_HoldLength,x
        lda     BitMaskTable,x
        ora     RNME_SFXStatus
        sta     RNME_SFXStatus

        RNME_NoSFXTrigger:
        lda     BitMaskTable,x
        and     RNME_SFXStatus      ; sfx playing?
        beq     RNME_UpdateMusic    ; branch if not
    ; update SFX
        dec     SFX_HoldLength,x
        beq     RNME_UpdateSFX
        jmp     RNME_UpdateMusic

        RNME_UpdateSFX:
        lda     SFX_pDataLo,x
        sta     RNME_pSFX
        lda     SFX_pDataHi,x
        sta     RNME_pSFX+1
        ldy     SFX_Index,x
        lda     [RNME_pSFX],y
        bne     @@10
    ; end sfx
        lda     BitMaskTable,x
        eor     RNME_SFXStatus
        sta     RNME_SFXStatus
        lda     BitMaskTable,x
        ora     RNME_Trigger
        sta     RNME_Trigger
        jmp     RNME_UpdateMusic
  @@10: sta     SFX_HoldLength,x
        iny
        txa
        asl
        asl
        tax
        lda     #%10111000
        sta     $4000,x
        lda     #$00
        sta     $4001,x
        lda     [RNME_pSFX],y
        sta     $4002,x
        iny
        lda     #$08
        sta     $4003,x
        txa
        lsr
        lsr
        tax
        tya
        sta     SFX_Index,x
;;;;;;;;;;;;    END SFX CODE
        RNME_UpdateMusic:
        lda     CHN_pOrderHi,x
        bne     RNME_UpdateChannel       ; if ptr is non-zero, update channel
        jmp     RNME_NextChannel         ; else channel is not in use, skip

        RNME_UpdateChannel:
        inc     CHN_Tick,x
        lda     CHN_Tick,x
        cmp     CHN_Speed,x
        beq     RNME_UpdateRow           ; new row when Tick = Speed
        jmp     RNME_NextChannel

        RNME_UpdateRow:
        lda     #$00
        sta     CHN_Tick,x              ; reset tick
        inc     CHN_Row,x               ; advance to next row
        lda     CHN_Row,x
        cmp     CHN_EndRow,x            ; reached end of pattern?
        beq     RNME_BeginNewPat
        jmp     RNME_NoNewPat

        RNME_BeginNewPat:
        lda     #$00
        sta     CHN_Row,x               ; reset row
        sta     CHN_PatPos,x            ; reset pattern position
        dec     CHN_PatLoopCount,x
        beq     RNME_AdvanceOrder
; play same pattern again (loop)
        inc     CHN_PatPos,x            ; skip the pattern length byte
        jmp     RNME_NoNewPat

        RNME_AdvanceOrder:
        sta     CHN_Transpose,x         ; default = no transpose
        lda     CHN_pOrderLo,x
        sta     RNME_pOrder
        lda     CHN_pOrderHi,x
        sta     RNME_pOrder+1

        RNME_LoadOrder:
        jsr     RNME_GetOrderByte
        bmi     RNME_OrderSpecial        ; special case if bit 7 set

        inc     CHN_PatLoopCount,x      ; prepare to play pattern once

        RNME_LoadPattern:
;        sta     CHN_Pattern,x
        asl
        tay
        lda     [RNME_pPatPtrTable],y    ; get low pointer to pattern
        sta     CHN_pPatternLo,x
        sta     RNME_pPattern
        iny
        lda     [RNME_pPatPtrTable],y    ; get high pointer to pattern
        sta     CHN_pPatternHi,x
        sta     RNME_pPattern+1

        jsr     RNME_GetPatByte          ; get one byte from the pattern
        sta     CHN_EndRow,x            ; this is the pattern length (in rows)
        jmp     RNME_CheckRowStat

        RNME_OrderSpecial:
        cmp     #$FB
        beq     RNME_SetOrderRepeat
        cmp     #$FC
        beq     RNME_CheckOrderRepeat
        cmp     #$FD
        beq     RNME_TransPat            ; $FD = set pattern transpose
        cmp     #$FE
        beq     RNME_GoOrderPos          ; $FE = jump to new order position
        bcs     RNME_StopPlaying         ; $FF = stop playing the track

        and     #$7F                    ; pattern loopcount in bit 0-6
        sta     CHN_PatLoopCount,x
        jsr     RNME_GetOrderByte        ; get pattern to loop
        bpl     RNME_LoadPattern         ; branch always

        RNME_SetOrderRepeat:
        jsr     RNME_GetOrderByte
        sta     CHN_OrderRepCount,x
        lda     CHN_OrderPos,x
        sta     CHN_OrderRepPos,x
        jmp     RNME_LoadOrder

        RNME_CheckOrderRepeat:
        dec     CHN_OrderRepCount,x
        beq     RNME_LoadOrder
        lda     CHN_OrderRepPos,x
        sta     CHN_OrderPos,x
        jmp     RNME_LoadOrder

        RNME_TransPat:
        jsr     RNME_GetOrderByte
        sta     CHN_Transpose,x
        jmp     RNME_LoadOrder

        RNME_GoOrderPos:
        iny
        lda     [RNME_pOrder],y          ; order position to jump to
        sta     CHN_OrderPos,x
        bpl     RNME_LoadOrder           ; branch always

        RNME_StopPlaying:
        lda     #$00
        sta     RNME_Status              ; turn off music
        sta     RNME_LastTune
        rts

        RNME_NoNewPat:
        lda     CHN_pPatternLo,x
        sta     RNME_pPattern
        lda     CHN_pPatternHi,x
        sta     RNME_pPattern+1

        RNME_CheckRowStat:

        RNME_NextChannel:
        dex                             ; done all channels?
        bmi     @@10
        jmp     RNME_ChannelLoop         ; if not, do another
  @@10: ldx     #1
; update square channels
  @@20: lda     SQR_DutyDelay,x
        beq     @@RNME_SetSquareVol
        dec     SQR_DutyDelay,x
        bne     @@RNME_SetSquareVol
        lda     ENV_WaveInfo,x
        asl
        asl
        and     #$C0
        sta     SQR_DutyCycle,x
    ; set the channel volume and frequency
        @@RNME_SetSquareVol:
        lda     ENV_CurrentVol,x
        ora     %00110000
        ora     SQR_DutyCycle,x
        sta     CHN_Reg0,x              ; set wave info & volume
        lda     CHN_FreqHi,x
        ora     #$08
        sta     CHN_Reg3,x
        dex
        bpl     @@20

; write to sound hardware regs
        ldx     #$00
  @@30: lda     BitMaskTable,x  ;
        and     RNME_SFXStatus      ;
        bne     @@RNME_WriteNextChn   ; don't write if playing sfx
        ldy     RNME_ChnOffset,x
        lsr     RNME_Trigger
        bcc     @@40
; new note trigger, write to all regs
        lda     CHN_Reg0,x
        sta     CHN_OldReg0,x
        sta     $4000,y
        lda     CHN_Reg1,x
        sta     CHN_OldReg1,x
        sta     $4001,y
        lda     CHN_Reg2,x
        sta     CHN_OldReg2,x
        sta     $4002,y
        lda     CHN_Reg3,x
        sta     CHN_OldReg3,x
        sta     $4003,y
        jmp     @@RNME_WriteNextChn
  @@40: lda     CHN_Reg0,x
        cmp     CHN_OldReg0,x
        beq     @@50
        sta     CHN_OldReg0,x
        sta     $4000,y
  @@50: lda     CHN_Reg1,x
        cmp     CHN_OldReg1,x
        beq     @@60
        sta     CHN_OldReg1,x
        sta     $4001,y
  @@60: lda     CHN_Reg2,x
        cmp     CHN_OldReg2,x
        beq     @@70
        sta     CHN_OldReg2,x
        sta     $4002,y
  @@70: lda     CHN_Reg3,x
        cmp     CHN_OldReg3,x
        beq     @@RNME_WriteNextChn
        sta     CHN_OldReg3,x
        sta     $4003,y
        @@RNME_WriteNextChn:
        inx
        cpx     #$02
        bne     @@30
        lsr     RNME_Trigger
        rts

;
; RNME_GetPatByte
;

        RNME_GetPatByte:
        ldy     CHN_PatPos,x
        inc     CHN_PatPos,x
        lda     [RNME_pPattern],y
        rts

;
; RNME_GetOrderByte
;

        RNME_GetOrderByte:
        ldy     CHN_OrderPos,x
        inc     CHN_OrderPos,x
        lda     [RNME_pOrder],y
        rts

;----------------------------------[ Data ]-----------------------------------

RNME_ChnOffset:
.db $00,$04,$08,$0C

; *** SONG DATA BEGINS HERE! ***

RNME_SongPtrTable:
.dw song0

; -------------------------- song 0 ------------------------------------------

song0:
.dw s0_order0 : .db 7
.db 0,0,0
.dw s0_patptrtable

s0_order0:
.db 0,$FE,0

s0_patptrtable:
.dw s0_pat0

s0_pat0:
.db $08,$00

; SFX DATA -------------------------------------------------------------------

RNME_SFXPtrTable:
.dw sfx0
.dw sfx1
.dw sfx2
.dw sfx3
.dw sfx4
.dw sfx5
.dw sfx6
.dw sfx7
.dw sfx8

sfx0:   ; bomb tick
.db $04, %01000010, 0
sfx1:   ; player move
.db $04, %01111000, 0
sfx2:   ; wall move
.db $03, %01101110
.db $03, %01001110, 0
sfx3:
.db $01, %00110011, 0
sfx4:
.db $03, $38
.db $03,$00
.db $03, $43
.db $03,$00
.db $03, $50
.db $03,$00
.db $03, $5F
.db $03,$00
.db $03, $71
.db $03,$00
.db $03, $86, 0
sfx5:
.db $03, $86
.db $03,$00
.db $03, $71
.db $03,$00
.db $03, $5F
.db $03,$00
.db $03, $50
.db $03,$00
.db $03, $43
.db $03,$00
.db $03, $38,0
sfx6:
.db $06, $71
.db $06, $97
.db $06, $71
.db $06, $97
.db $06, $71
.db $06, $97,0
sfx7:
.db $07, $C9
.db $07, $00
.db $07, $C9
.db $07, $00
.db $07, $C9
.db $07, $00
.db $07, $C9
.db $02, $00
.db $10, $B3
.db $10, $7F
.db $10, $A9
.db $10, $79
.db $18, $C9
.db $18, $8E
.db $30, $00
.db $10, $B3
.db $10, $7F
.db $10, $A9
.db $10, $79
.db $18, $C9
.db $18, $8E,0
sfx8:
.db $03,$6A
.db $0C,$64
.db $03,$54
.db $03,$00
.db $03,$54
.db $03,$00
.db $06,$64
.db $06,$5F
.db $06,$00
.db $07,$4B
.db $07,$43
.db $03,$3F
.db $03,$64
.db $03,$3F
.db $03,$64
.db $03,$3F
.db $03,$64
.db $03,$3F
.db $03,$64
.db $03,$3F
.db $03,$64
.db $03,$3F
.db $03,$64
.db $03,$3F
.db $03,$64
.db 0
