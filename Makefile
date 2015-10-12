BIN = XcodeGenerateConstants
DIST = /usr/local/bin

install:
	@echo "Install $(BIN)"
	cp $(BIN).swift $(DIST)/$(BIN)
	chmod +x $(DIST)/$(BIN)

