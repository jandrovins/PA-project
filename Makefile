


all:
	$(MAKE) -C ALU all

clean: clean-dir-ALU

clean-dir-%: %
	$(MAKE) -C $< clean
