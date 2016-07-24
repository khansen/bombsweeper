#
#    Copyright (C) 2002, 2004 Kent Hansen.
#
#    This file is part of BombSweeper.
#
#    BombSweeper is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    BombSweeper is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

# Linker script for BombSweeper
# Define RAM regions linker can use
ram{start=0x0000,end=0x0180}
ram{start=0x0200,end=0x0800}
# Output goes to file "bombswpr.nes"
output{file=bombswpr.nes}
# iNES header
copy{file=bombswpr.hdr}
# PRG bank
bank{size=16384}
link{file=bombswpr.o, origin=0xC000}
pad{origin=0xFFFA}
link{file=vectors.o}
# CHR bank
bank{size=8192}
copy{file=graphics/bg.chr}
copy{file=graphics/sprite.chr}
