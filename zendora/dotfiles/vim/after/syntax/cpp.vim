syn match cppReceiver     "[_a-zA-Z]\w*\s*\."me=e-1
syn match cppIndexee      "\w\+\s*\["me=e-1
syn match cppNamespace    "\w\+\s*::"me=e-2
syn match cppNamespaceStd "std\s*::"me=e-2
syn match cppColonColon   "::"

syn keyword cppAuto       auto
syn keyword cppConst      const

hi def link cppNamespace  myShadow
hi def link cppColonColon myShadow
hi def link cppIndexee    cppReceiver
