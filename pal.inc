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

; PAL_LoadPalette
; ===============

        PAL_LoadPalette:
        sta     pData
        sty     pData+1
        ldy     #$1F
  @@10: lda     [pData],y
        sta     RAMPalette,y
        dey
        bpl     @@10
        rts

; PAL_SetPalette
; ==============

        PAL_SetPalette:
        jsr     PAL_StrSetup
        ldx     #$1F
  @@10: lda     RAMPalette,x
        sta     PPUString+3,x
        dex
        bpl     @@10
        lda     #$01
        sta     PPUDataPending
        jmp     WaitNMIPass

;-----------------------------------------------------------------------------

; PAL_FadeFromBlack
; =================
; Fades in the currently loaded palette.

        PAL_FadeFromBlack:
        jsr     PAL_StrSetup
        ldx     #$1F
  @@10: lda     RAMPalette,x
        and     #$0F            ; color intensity = 0
        sta     PPUString+3,x
        dex
        bpl     @@10

        jsr     PAL_FadeDelay
        jsr     PAL_FadeFromBlackStep
        jsr     PAL_FadeDelay
        jsr     PAL_FadeFromBlackStep
        jsr     PAL_FadeDelay
        jsr     PAL_FadeFromBlackStep
        jsr     PAL_FadeDelay
        jsr     PAL_FadeFromBlackStep
        jmp     WaitNMIPass

        PAL_FadeFromBlackStep:
        ldx     #$1F
  @@10: lda     PPUString+3,x
        cmp     RAMPalette,x    ; has color reached full intensity?
        bcs     @@20            ; if yes, don't modify it
        adc     #$10            ; increase color intensity by 1
        sta     PPUString+3,x
  @@20: dex
        bpl     @@10
        rts

;-----------------------------------------------------------------------------

; PAL_FadeToBlack
; ===============
; Fades the currently loaded palette to all black.

        PAL_FadeToBlack:
        jsr     PAL_StrSetup
        ldx     #$1F
  @@10: lda     RAMPalette,x
        sta     PPUString+3,x
        dex
        bpl     @@10

        jsr     PAL_FadeToBlackStep
        jsr     PAL_FadeDelay
        jsr     PAL_FadeToBlackStep
        jsr     PAL_FadeDelay
        jsr     PAL_FadeToBlackStep
        jsr     PAL_FadeDelay
        jsr     PAL_FadeToBlackStep
        jmp     PAL_FadeDelay

        PAL_FadeToBlackStep:
        ldx     #$1F
  @@10: lda     PPUString+3,x
        sec
        sbc     #$10            ; decrease color intensity by 1
        bcs     @@20            ; if result is < 0...
        lda     #$0F            ; ... color = black
  @@20: sta     PPUString+3,x
        dex
        bpl     @@10
        rts

;-----------------------------------------------------------------------------

        PAL_StrSetup:
        lda     #$20
        sta     PPUString+2
        lda     #$3F
        sta     PPUString
        lda     #$00
        sta     PPUString+1
        sta     PPUString+35
        rts

        PAL_FadeDelay:
        lda     #$01
        sta     PPUDataPending
        ldy     #$04
  @@10: jsr     WaitNMIPass
        dey
        bne     @@10
        rts
