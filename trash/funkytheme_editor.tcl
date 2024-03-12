
#
# The tcl script sourced must provides:
# funkythemeeditor_embed_init  $w
# funkythemeeditor_embed_reset $w
# funkythemeeditor_embed_exit
# TODO generer theme viable avec 4 couleurs dont 2 par default:
# - couleur de frame
# - couleur de police
# - couleur de lumière ambiante (gris par defaut)
# - couleur de lumière directionnelle (blanc par defaut)
source ./flutiou.tcl

wm geometry . "1950x650+300+300"

ttk::frame .root

canvas     .root.edc -width 490 \
    -yscrollcommand ".root.editor_s set" \
    -yscrollincrement 5
frame      .root.edc.editor
scrollbar  .root.editor_s -command ".root.edc yview"
ttk::frame .root.userwin

pack .root.edc   -side left -expand 0 -fill both
pack .root.editor_s -side left -expand 0 -fill y
pack .root.userwin  -side right -expand 1 -fill both

funkythemeeditor_embed_init .root.userwin

proc funk_exit {} {
    funkythemeeditor_embed_exit
    exit
}

bind all <Escape> exit
wm title . "Funkytheme editor"

# editor won't use ttk to be clear
set m [menu .root.menu]
. configure -menu $m
menu $m.main -tearoff 0
$m add cascade -label "Theme Editor" -menu $m.main -underline 0
$m.main add command -label "Exit" -command exit

frame .root.edc.editor.colors
frame .root.edc.editor.empty
pack .root.edc.editor.colors -side top -expand 0 -fill both
pack .root.edc.editor.empty  -side bottom -expand 1 -fill both

set tcolors_base [list \
    -bg             \
    -fg             \
    -buttonbg       \
    -buttonfg       \
]

set tcolors_auto [ list \
    -window         \
    -selectbg       \
    -selectfg       \
    -disabledbg     \
    -disabledfg     \
    -darkest        \
    -darker         \
    -dark           \
    -lighter        \
    -lightest       \
    -focuscolor     \
    -checklight     \
    -treeitem       \
]

array set color_original [array get ::funky::theme::colors]
array set color_edited   [array get ::funky::theme::colors]
proc update_view {} {
    global color_edited
    set newtheme [::funky::theme::reconfigure [array get color_edited]]
    #funkythemeeditor_embed_reset .root.userwin
}

proc update_color {name win} {
    global color_edited
    set newcol [tk_chooseColor -initialcolor $color_edited(-$name) -parent . -title "Setting $name color"]
    if {$newcol ne ""} {
        $win.${name}_demo configure -bg $newcol
        $win.${name}_color configure -text $newcol
        set color_edited(-${name}) $newcol
    }
    update_view
}

set wbase [labelframe .root.edc.editor.colors.base -text "Base colors"]
pack $wbase -side top -expand 0 -fill x -padx {10 10} -pady {10 10} -ipady 5
set bcolindex 0
foreach {cname} $tcolors_base {
    global color_edited
    set wname [string trimleft $cname -]
    set colval  $color_edited($cname)
    label $wbase.${wname}_label -text $cname
    label $wbase.${wname}_color -text $colval -relief sunken
    frame $wbase.${wname}_demo -bg $colval -width 80
    button $wbase.${wname}_pick \
        -text "Pick..." -command "update_color $wname $wbase"

    grid $wbase.${wname}_label -column 0 -row $bcolindex
    grid $wbase.${wname}_color -column 1 -row $bcolindex
    grid $wbase.${wname}_demo  -column 2 -row $bcolindex
    grid $wbase.${wname}_pick  -column 3 -row $bcolindex
    grid configure $wbase.${wname}_label -sticky w -padx {10 0}
    grid configure $wbase.${wname}_color -sticky ew -padx {10 0}
    grid configure $wbase.${wname}_demo  -sticky snew -padx {10 0}
    grid configure $wbase.${wname}_pick  -padx {10 10}
    incr bcolindex
}

set wauto [labelframe .root.edc.editor.colors.auto -text "Derived colors"]
pack $wauto -side top -expand 0 -fill x -padx {10 10} -pady {10 10} -ipady 5


array set acolarray {}
proc update_acol_button {auto name} {
    global acolarray
    set lopt $auto.${name}
    if {$acolarray($lopt) eq "manual"} {
        ${lopt}_pick  configure -state normal
        ${lopt}_label configure -state normal
        ${lopt}_color configure -state normal
    } else {
        ${lopt}_pick  configure -state disabled
        ${lopt}_label configure -state disabled
        ${lopt}_color configure -state disabled
        set original_color $::funky::theme::colors(-$name)
        # todo recompute auto colors
        ${lopt}_demo  configure -bg $original_color
        ${lopt}_color configure -text $original_color
        update_view
    }
}

labelframe $wauto.config -text "Automatic Options"
grid configure $wauto.config -columnspan 6 -sticky ew -padx {10 10} -pady {10 25}
grid $wauto.config -column 0 -row 0

label $wauto.config.light_label -text "Lightning color"
label $wauto.config.light_color -text "#ffffff" -relief sunken
frame $wauto.config.light_demo -bg white -width 80
button $wauto.config.light_pick \
           -text "Pick..." -command "update_color lightning white"
grid $wauto.config.light_label -column 0 -row 8
grid $wauto.config.light_color -column 1 -row 8
grid $wauto.config.light_demo  -column 2 -row 8
grid $wauto.config.light_pick  -column 3 -row 8





set default_contrast 50
label   $wauto.config.contrast_l -text "Contrast: "
spinbox $wauto.config.contrast_s -from 0 -to 100 -width 4 \
    -command {set default_contrast %s}
scale   $wauto.config.contrast_v -orient horizontal -showvalue 0 \
    -from 0 -to 100 -variable default_contrast \
    -command "$wauto.config.contrast_s set"
$wauto.config.contrast_s set $default_contrast
grid $wauto.config.contrast_l -column 0 -row 0 -padx {10 0} -pady {10 5} -sticky e
grid $wauto.config.contrast_v -column 1 -row 0 -padx {10 0} -pady {10 5} -sticky ew
grid $wauto.config.contrast_s -column 2 -row 0 -padx {5 10} -pady {10 5}
grid columnconfigure $wauto.config 0 -weight 0
grid columnconfigure $wauto.config 1 -weight 4
grid columnconfigure $wauto.config 2 -weight 0

set default_bgradient 50
label   $wauto.config.bgradient_l -text "Default button gradient: "
spinbox $wauto.config.bgradient_s -from 0 -to 100 -width 4 \
    -command {set default_bgradient %s}
scale   $wauto.config.bgradient_v -orient horizontal -showvalue 0 \
    -from 0 -to 100 -variable default_bgradient \
    -command "$wauto.config.bgradient_s set"
$wauto.config.bgradient_s set $default_bgradient
grid $wauto.config.bgradient_l -column 0 -row 1 -padx {10 0} -pady {10 10} -sticky e
grid $wauto.config.bgradient_v -column 1 -row 1 -padx {10 0} -pady {10 10} -sticky ew
grid $wauto.config.bgradient_s -column 2 -row 1 -padx {5 10} -pady {10 10}

set default_b2gradient 50
label   $wauto.config.b2gradient_l -text "Play buttons gradient: "
spinbox $wauto.config.b2gradient_s -from 0 -to 100 -width 4 \
    -command {set default_b2gradient %s}
scale   $wauto.config.b2gradient_v -orient horizontal -showvalue 0 \
    -from 0 -to 100 -variable default_b2gradient \
    -command "$wauto.config.b2gradient_s set"
$wauto.config.b2gradient_s set $default_b2gradient
grid $wauto.config.b2gradient_l -column 0 -row 2 -padx {10 0} -pady {10 10} -sticky e
grid $wauto.config.b2gradient_v -column 1 -row 2 -padx {10 0} -pady {10 10} -sticky ew
grid $wauto.config.b2gradient_s -column 2 -row 2 -padx {5 10} -pady {10 10}


set default_tgradient 50
label   $wauto.config.tgradient_l -text "Tree heading gradient: "
spinbox $wauto.config.tgradient_s -from 0 -to 100 -width 4 \
    -command {set default_tgradient %s}
scale   $wauto.config.tgradient_v -orient horizontal -showvalue 0 \
    -from 0 -to 100 -variable default_tgradient \
    -command "$wauto.config.tgradient_s set"
$wauto.config.tgradient_s set $default_tgradient
grid $wauto.config.tgradient_l -column 0 -row 3 -padx {10 0} -pady {10 10} -sticky e
grid $wauto.config.tgradient_v -column 1 -row 3 -padx {10 0} -pady {10 10} -sticky ew
grid $wauto.config.tgradient_s -column 2 -row 3 -padx {5 10} -pady {10 10}



set acolindex 1
foreach {cname} $tcolors_auto {
    global color_edited
    global acolarray
    set wname [string trimleft $cname -]
    set colval  $color_edited($cname)
    label $wauto.${wname}_label -text $cname -state disabled
    label $wauto.${wname}_color -text $colval -relief sunken -state disabled
    frame $wauto.${wname}_demo -bg $colval -width 80
    set lopt $wauto.${wname}
    radiobutton $wauto.${wname}_auto -text   "Auto" \
        -variable acolarray($lopt) -value "auto" -fg black \
        -command "update_acol_button $wauto $wname"
    radiobutton $wauto.${wname}_manual -text "Manual" \
        -variable acolarray($lopt) -value "manual" -fg black \
        -command "update_acol_button $wauto $wname"
    $wauto.${wname}_auto select

    button $wauto.${wname}_pick \
        -text "Pick..." -command "update_color $wname $wauto" -state disabled

    grid $wauto.${wname}_label -column 0 -row $acolindex
    grid $wauto.${wname}_color -column 1 -row $acolindex
    grid $wauto.${wname}_demo  -column 2 -row $acolindex
    grid $wauto.${wname}_pick  -column 3 -row $acolindex
    grid $wauto.${wname}_auto  -column 4 -row $acolindex
    grid $wauto.${wname}_manual  -column 5 -row $acolindex
    grid configure $wauto.${wname}_label -sticky w -padx {10 0}
    grid configure $wauto.${wname}_color -sticky ew -padx {10 00}
    grid configure $wauto.${wname}_demo  -sticky snew -padx {10 0}
    grid configure $wauto.${wname}_pick  -padx {10 10}
    grid configure $wauto.${wname}_auto  -sticky w -padx {0 0}
    grid configure $wauto.${wname}_manual  -sticky w -padx {0 10}
    incr acolindex
}
pack .root -expand 1 -fill both
.root.edc create window 0 0 -anchor nw -height 900 -window .root.edc.editor
.root.edc configure -scrollregion [.root.edc bbox all]

