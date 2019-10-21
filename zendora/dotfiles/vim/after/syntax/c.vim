syn match cOpenParen    "?=("         contains=cParen,cCppParen
syn match cFunc         "\w\+\s*(\@=" contains=cOpenParen
syn match cComma        ","
syn match cSingleLetter "\<[a-z]\>"

hi def link cFunc         Function
hi def link cComma        myStandout
hi def link cSingleLetter mySmell
