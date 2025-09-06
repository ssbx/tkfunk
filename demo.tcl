set pwdir [file normalize [file dirname [info script] ]]
lappend auto_path $pwdir
package require Tcl         8.6
package require Ttk         8.6
package require TkFunk 1.0
package require TkFunBt 1.0

ttk::frame .buttons
ttk::button .buttons.b1 -text "b1"
grid .buttons.b1

ttk::labelframe .buttons2 -text "label frame"
ttk::button .buttons2.b2 -text "b2"
grid .buttons2.b2

ttk::treeview .tv

grid .buttons  -column 0 -row 0 -sticky ns
grid .buttons2 -column 0 -row 1 -sticky ns
grid .tv -column 1 -row 0 -rowspan 2 -sticky nsew

grid rowconfigure . 0 -weight 1
grid rowconfigure . 1 -weight 1
grid columnconfigure . 0 -weight 0
grid columnconfigure . 1 -weight 1
