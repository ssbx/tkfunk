#
# from https://wiki.tcl-lang.org/page/A+scrolled+frame
#

namespace eval ::w::extratable {}

proc ::w::extratable::extratable {w args} {

    variable {}

    # create a scrolled frame
    ttk::frame $w -style Inverse.TFrame

    # trap the reference
    rename $w ::w::extratable::_$w

    # redirect to dispatch
    interp alias {} $w {} ::w::extratable::dispatch $w

    # create scrollable internal frame
    ttk::frame $w.scrolled -style Inverse.TFrame

    # place it
    place $w.scrolled -in $w -x 0 -y 0

    # init internal data
    set ($w:vheight)    0
    set ($w:vwidth)     0
    set ($w:vtop)       0
    set ($w:vleft)      0
    set ($w:xscroll)    ""
    set ($w:yscroll)    ""
    set ($w:width)      0
    set ($w:height)     0
    set ($w:fillx)      0
    set ($w:filly)      0

    # configure
    if {$args != ""} { uplevel 1 ::w::extratable::config $w $args }

    # bind <Configure>
    bind $w <Configure> [namespace code [list resize $w]]
    bind $w.scrolled <Configure> [namespace code [list resize $w]]

    # return widget ref
    return $w
}

proc ::w::extratable::dispatch {w cmd args} {

    variable {}
    switch -glob -- $cmd {
        con*    { uplevel 1 [linsert $args 0 ::w::extratable::config $w] }
        xvi*    { uplevel 1 [linsert $args 0 ::w::extratable::xview  $w] }
        yvi*    { uplevel 1 [linsert $args 0 ::w::extratable::yview  $w] }
        setlist { uplevel 1 [linsert $args 0 ::w::extratable::setlist $w] }
        default { uplevel 1 [linsert $args 0 ::w::extratable::_$w    $cmd] }
    }
}

proc ::w::extratable::setlist {w args} {
    set dirlist  [lindex $args 0]
    set filelist [lindex $args 1]
    puts "hura $dirlist"
    puts "hura $filelist"
}

# configure widget operation
proc ::w::extratable::config {w args} {
    variable {}
    set options {}
    set flag 0
    foreach {key value} $args {
        switch -glob -- $key {
            -fill {
                # new fill option: what should the scrolled object do if
                # it is smaller than the viewing window?
                if {$value == "none"} {
                    set ($w:fillx) 0
                    set ($w:filly) 0
                } elseif {$value == "x"} {
                    set ($w:fillx) 1
                    set ($w:filly) 0
                } elseif {$value == "y"} {
                    set ($w:fillx) 0
                    set ($w:filly) 1
                } elseif {$value == "both"} {
                    set ($w:fillx) 1
                    set ($w:filly) 1
                } else {
                    error "invalid value: should be \"$w configure -fill value\", where \"value\" is \"x\", \"y\", \"none\", or \"both\""
                }
                resize $w force
                set flag 1
            }
            -xsc*   {
                # new xscroll option
                set ($w:xscroll) $value
                set flag 1
            }
            -ysc*   {
                # new yscroll option
                set ($w:yscroll) $value
                set flag 1
            }
            default {
                lappend options $key $value
            }
        }
    }

    # check if needed
    if {!$flag || $options != ""} {
        # call frame config
        uplevel 1 [linsert $options 0 ::w::extratable::_$w config]
    }
}

# --------------
# resize proc
#
# Update the scrollbars if necessary, in response to a change in either the viewing
# window
# or the scrolled object.
# Replaces the old resize and the old vresize
# A <Configure> call may mean any change to the viewing window or the scrolled object.
# We only need to resize the scrollbars if the size of one of these objects has changed.
# Usually the window sizes have not changed, and so the proc will not resize the
# scrollbars.
# --------------
# parm1: widget name
# parm2: pass anything to force resize even if dimensions are unchanged
# --------------
proc ::w::extratable::resize {w args} {
    variable {}
    set force [llength $args]

    set _vheight     $($w:vheight)
    set _vwidth      $($w:vwidth)

    # compute new height & width
    set ($w:vheight) [winfo reqheight $w.scrolled]
    set ($w:vwidth)  [winfo reqwidth  $w.scrolled]

    # The size may have changed, e.g. by manual resizing of the window
    set _height     $($w:height)
    set _width      $($w:width)
    set ($w:height) [winfo height $w] ;# gives the actual height of the viewing window
    set ($w:width)  [winfo width  $w] ;# gives the actual width of the viewing window

    if {$force || $($w:vheight) != $_vheight || $($w:height) != $_height} {
        # resize the vertical scroll bar
        yview $w scroll 0 unit
        # yset $w
    }
    if {$force || $($w:vwidth) != $_vwidth || $($w:width) != $_width} {
        # resize the horizontal scroll bar
        xview $w scroll 0 unit
        # xset $w
    }
}

# --------------
# xset proc
#
# resize the visible part
# --------------
# parm1: widget name
# --------------
proc ::w::extratable::xset {w} {

    variable {}

    # call the xscroll command
    set cmd $($w:xscroll)
    if {$cmd != ""} {
        catch { eval $cmd [xview $w] }
    }
}

# --------------
# yset proc
#
# resize the visible part
# --------------
# parm1: widget name
# --------------
proc ::w::extratable::yset {w} {

    variable {}

    # call the yscroll command
    set cmd $($w:yscroll)
    if {$cmd != ""} {
        catch { eval $cmd [yview $w] }
    }
}

# -------------
# xview
#
# called on horizontal scrolling
# -------------
# parm1: widget path
# parm2: optional moveto or scroll
# parm3: fraction if parm2 == moveto, count unit if parm2 == scroll
# -------------
# return: scrolling info if parm2 is empty
# -------------
proc ::w::extratable::xview {w {cmd ""} args} {

    variable {}

    # check args
    set len [llength $args]
    switch -glob -- $cmd {
        ""      {set args {}}
        mov*    {
            if {$len != 1} {
                error "wrong # args: should be \"$w xview moveto fraction\""
            }
        }
        scr*    {
            if {$len != 2} {
                error "wrong # args: should be \"$w xview scroll count unit\""
            }
        }
        default {
            error "unknown operation \"$cmd\": should be empty, moveto or scroll"
        }
    }

    # save old values:
    set _vleft $($w:vleft)
    set _vwidth $($w:vwidth)
    set _width  $($w:width)

    # compute new vleft
    set count ""
    switch $len {
        0 {
            # return fractions
            if {$_vwidth == 0} {
                return {0 1}
            }
            set first [expr {double($_vleft) / $_vwidth}]
            set last [expr {double($_vleft + $_width) / $_vwidth}]
            if {$last > 1.0} {
                return {0 1}
            }
            return [list $first $last]
        }
        1 {
            # absolute movement
            set vleft [expr {int(double($args) * $_vwidth)}]
        }
        2 {
            # relative movement
            foreach {count unit} $args break
            if {[string match p* $unit]} {
                set count [expr {$count * 9}]
            }
            set vleft [expr {$_vleft + $count * 0.1 * $_width}]
        }
    }

    if {$vleft + $_width > $_vwidth} {
        set vleft [expr {$_vwidth - $_width}]
    }

    if {$vleft < 0} {
        set vleft 0
    }

    if {$vleft != $_vleft || $count == 0} {

        set ($w:vleft) $vleft
        xset $w
        if {$($w:fillx) && ($_vwidth < $_width || $($w:xscroll) == "") } {
            # "scrolled object" is not scrolled, because it is too small or because
            # no scrollbar was requested
            # fillx means that, in these cases, we must tell the object what its
            # width should be
            place $w.scrolled -in $w -x [expr {-$vleft}] -width $_width
            puts "place $w.scrolled -in $w -x [expr {-$vleft}] -width $_width"
        } else {
            place $w.scrolled -in $w -x [expr {-$vleft}] -width {}
            puts "place $w.scrolled -in $w -x [expr {-$vleft}] -width {}"
        }
    }
}

# -------------
# yview
#
# called on vertical scrolling
# -------------
# parm1: widget path
# parm2: optional moveto or scroll
# parm3: fraction if parm2 == moveto, count unit if parm2 == scroll
# -------------
# return: scrolling info if parm2 is empty
# -------------
proc ::w::extratable::yview {w {cmd ""} args} {

    variable {}

    # check args
    set len [llength $args]
    switch -glob -- $cmd {
        ""   {
            set args {}
        }
        mov* {
            if {$len != 1} {
                error "wrong # args: should be \"$w yview moveto fraction\""
            }
        }
        scr* {
            if {$len != 2} {
                error "wrong # args: should be \"$w yview scroll count unit\""
            }
        }
        default {
            error "unknown operation \"$cmd\": should be empty, moveto or scroll"
        }
    }

    # save old values
    set _vtop $($w:vtop)
    set _vheight $($w:vheight)
    #    set _height [winfo height $w]
    set _height $($w:height)
    # compute new vtop
    set count ""
    switch $len {
        0 {
            # return fractions
            if {$_vheight == 0} {
                return {0 1}
            }
            set first [expr {double($_vtop) / $_vheight}]
            set last [expr {double($_vtop + $_height) / $_vheight}]
            if {$last > 1.0} {
                return {0 1}
            }
            return [list $first $last]
        }
        1 {
            # absolute movement
            set vtop [expr {int(double($args) * $_vheight)}]
        }
        2 {
            # relative movement
            foreach {count unit} $args break
            if {[string match p* $unit]} {
                set count [expr {$count * 9}]
            }
            set vtop [expr {$_vtop + $count * 0.1 * $_height}]
        }
    }

    if {$vtop + $_height > $_vheight} {
        set vtop [expr {$_vheight - $_height}]
    }

    if {$vtop < 0} {
        set vtop 0
    }

    if {$vtop != $_vtop || $count == 0} {
        set ($w:vtop) $vtop
        yset $w
        if {$($w:filly) && ($_vheight < $_height || $($w:yscroll) == "")} {
            # "scrolled object" is not scrolled, because it is too small or
            # because no scrollbar was requested
            # filly means that, in these cases, we must tell the object what its
            # height should be
            place $w.scrolled -in $w -y [expr {-$vtop}] -height $_height
            puts "place $w.scrolled -in $w -y [expr {-$vtop}] -height $_height"
        } else {
            place $w.scrolled -in $w -y [expr {-$vtop}] -height {}
            puts "place $w.scrolled -in $w -y [expr {-$vtop}] -height {}"
        }
    }
}

