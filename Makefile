BIN = XcodeGenerateConstants
DIST = /usr/local/bin

install:
	@echo "Install $(BIN)"
	cp -f $(BIN).swift $(DIST)/$(BIN)
	chmod +x $(DIST)/$(BIN)

