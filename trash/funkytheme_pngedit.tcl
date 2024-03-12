
frame .root -width 100 -height 100
pack .root -fill both -expand 1
frame .root.ctrl
button .root.ctrl.save -text "sauver"
button .root.ctrl.quit -text "quiter"
pack .root.ctrl.save -side top -fill x
pack .root.ctrl.quit -side top -fill x
pack .root.ctrl -side left -fill y -expand 0
set imgedit [image create photo -file "funky/imgs/ximage-treeviewheading1.png"]

set pixelmag 1
set height [image height $imgedit]
set width  [image width $imgedit]
set pixelsize 10

puts "$imgedit $height $width"

canvas .root.canv \
    -width [expr $width * $pixelsize] \
    -height [expr $height * $pixelsize] \
    -background red

set table [list]
for {set x 0} {$x < $width} {incr x} {
    set column [list]
    for {set y 0} {$y < $height} {incr y} {
        set cell_color [$imgedit get $x $y]
        set cell_hex_color [format #%02X%02X%02X \
            [lindex $cell_color 0] \
            [lindex $cell_color 1] \
            [lindex $cell_color 2]]
        puts $cell_hex_color

        set x_nw [expr $x * $pixelsize]
        set y_nw [expr $y * $pixelsize]
        set x_se [expr $x_nw + $pixelsize]
        set y_se [expr $y_nw + $pixelsize]
        set cell [.root.canv create rectangle $x_nw $y_nw $x_se $y_se \
            -fill $cell_hex_color -outline #000000 ]
        lappend column $cell
    }
    lappend table $column
}
pack .root.canv -side right -expand 1 -fill both

proc set_color {} {
    set item [.root.canv find withtag [list current]]
    .root.canv itemconfigure $item -fill #000000
    puts "$item"
}

bind .root.canv <1> {set_color}


# set t .
#
# set _paint(top) $t
# set _paint(width) 50
# set _paint(height) 50
#
# set _paint(bg) red
# set _paint(color) black
#
# set imgedit [image create photo "funky/imgs/ximage-button.png"]
#
# # Canvas
#
# set _paint(can) [canvas $t.c \
#    -width $_paint(width) \
#    -height $_paint(height) \
#    -background $_paint(bg) \
#    ]
#
# grid $_paint(can) -row 0 -column 0
#
# # Image
#
# #set _paint(image) [image create photo \
#    -width $_paint(width) \
#    -height $_paint(height) \
#    -palette 256/256/256 \
#    ]
# set _paint(image) $imgedit
# # Canvas image item
#
# set _paint(image_id) [$_paint(can) create image \
#    0 0 \
#    -anchor nw \
#    -image $_paint(image) \
#    ]
#
# # Paint pixel at a X,Y coord
#
# proc Paint {x y} {
#    global _paint
#
#    if {$x >= 0 && $y >= 0} {
#        $_paint(image) put $_paint(color) \
#            -to $x $y \
#                [expr {$x + 1}] [expr {$y + 1}]
#    }
# }
#
# bind $_paint(can) <1> {Paint %x %y}
# bind $_paint(can) <B1-Motion> {Paint %x %y}
#
# # Button 3 will select a new paint color
#
# proc ChangeColor {} {
#    global _paint
#    set _paint(color) [tk_chooseColor]
#    raise $_paint(top)
# }
#
# bind $_paint(can) <3> {ChangeColor}
# bind $_paint(can) <MouseWheel> {
#     if {%D > 0} {
#         puts "up"
#         $_paint(can) scale all 0 0 2 2
#     } else {
#         $_paint(can) scale all 0 0 1 1
#         puts "down"
#     }
# }
