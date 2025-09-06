
set cols [ dict create \
 bg          #f5f6f7 \
 fg          #5c616c \
 disabledbg  #fbfcfc \
 disabledfg  #a9acb2 \
 selectbg    #5294e2 \
 selectfg    #ffffff \
 troughcolor #f5f6f7 \
 fieldbg     #ffffff \
 window      #ffffff \
 focuscolor  #5c616c \
 checklight  #fbfcfc \
 buttonbg    #fcfdfd \
 buttonfg    #5c616c \
 buttonborder        #cfd6e6 \
 buttonactivebg      #d3d8e2 \
 buttonactiveborder  #b7c0d3 \
 buttonhoverbg       #ffffff \
 buttonhoverborder   #cfd6e6 \
 buttoninsensitivebg #fbfcfc \
 buttoninsensitiveborder     #e2e7ef \
 buttonemptycolor            #f5f6f7 \
 treeviewfieldborder         #dde3e9 \
 slidertrough                #fcfcfc \
 prelightscrollbar           #d3d4d8 \
 insensscrollbar             #eaebed \
 normalscrollbar             #b8babf \
]

#pack [frame .auto] -fill x
#pack [ frame  .auto.bg_demo -bg #ffffff] -side top -expand true -fill both
#pack [ button .auto.bg_demo.edit -text "auto bg" -command "" ] -side right
#pack [ frame  .auto.fg_demo -bg #ffffff] -side top -expand true -fill both
#pack [ button .auto.fg_demo.edit -text "auto fg" -command "" ] -side right
#pack [ frame  .auto.field_demo -bg #ffffff] -side top -expand true -fill both
#pack [ button .auto.field_demo.edit -text "auto field" -command "" ] -side right

pack [frame .root] -expand 1 -fill both

proc set_col {k v} {
  variable cols
  set choice [tk_chooseColor -initialcolor $v -title $k]
  dict set cols $k $choice
  .root.$k.demo configure -bg $choice
}

foreach {k v} $cols {
  set f [frame .root.$k ]
  pack [ frame  $f.demo -bg $v ] -side left -expand true -fill both
  pack [ button $f.edit -text $k -command [ list set_col $k $v ] ] -side right

  pack $f -side top -expand true -anchor w -fill x
}

proc export_tests {} {
  variable cols
  set scriptdir [file dirname [file normalize [info script]]]
  set fd [ open "$scriptdir/tests.colorscheme" w ]
  foreach {k v} $cols {
    puts $fd "$k $v"
  }
  close $fd
  exec "./flutiou.sh"
}

pack [ button .root.export -text "export" -command [ list export_tests ] ] -side top

