
include ../makefile.defs


BEEA_DEPS =
DIV_DEPS = BEEA.v


all: all_waves all_synth

all_waves: BEEA_wave DIV_wave

all_synth: BEEA_synth DIV_synth


BEEA_wave: VERI_INCL = $(BEEA_DEPS)
BEEA_wave: BEEA.fst

DIV_wave: VERI_INCL = $(DIV_DEPS)
DIV_wave: DIV.fst


BEEA_synth: VERI_INCL = $(BEEA_DEPS)
BEEA_synth: BEEA.blif

DIV_synth: VERI_INCL = $(DIV_DEPS)
DIV_synth: DIV.blif
