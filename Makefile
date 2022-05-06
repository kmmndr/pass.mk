PREFIX?=/usr/local

install:
	@install -Dm755 pass.mk ${PREFIX}/bin/pass.mk

uninstall:
	@rm ${PREFIX}/bin/pass.mk
