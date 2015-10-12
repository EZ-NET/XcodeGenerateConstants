# XcodeGenerateConstants

Generate Swift code which defines constants written in a Property List file.

## How to Install

```
git clone https://github.com/EZ-NET/XcodeGenerateConstants.git
cd XcodeGenerateConstants

sudo make install
```

## How to Use

```
XcodeGenerateConstraints *NAME *DestinationPath
```

The script read ```~/Library/XcodeGenerateConstraints/*NAME.plist``` file, then generate ```*NAME.swift``` file to ```*DestinationPath``` directory.
