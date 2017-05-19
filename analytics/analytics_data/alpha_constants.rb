module AlphaConstants
	REGEXES=[
		{"name": "Base64", "regex": /^(?:[A-Za-z0-9+]{4})*(?:[A-Za-z0-9+]{2}==|[A-Za-z0-9+]{3}=)?$/},
		{"name": "Hexidecimal", "regex": /^[0-9a-fA-F]+$/},
		{"name": "YouTube ID (11 chars)", "regex": /^[0-9a-zA-Z]{11}$/},
		{"name": "Bitly ID (7 chars)", "regex": /^[0-9a-zA-Z]{7}$/},
		{"name": "UTF-8 (4 Hex chars)", "regex": /^[0-9a-fA-F]{4}$/}
	]
end