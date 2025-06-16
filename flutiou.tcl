package require Tcl         8.6
package require Ttk         8.6
package require msgcat      1.6

namespace eval ::flutiou {
    variable libdir  [file normalize [file dirname [info script] ]]
    variable userdir [file join $::env(HOME) .flutio]
    variable images
    variable playlist_revision
    variable collection

    variable player_com_in
    variable player_com_out
    variable player_com_err
    variable player_com_pid 0
}

# init msgcat
namespace import ::msgcat::mc

# init and set theme TODO
set use 0

#if {$use == "old"} {
#    source [file join $::flutiou::libdir lib_funkytheme.tcl]
#    ttk::style theme use Funky
#    . configure -background [ttk::style lookup Funky -background {} white]
#} elseif { $use == "arc"} {
#    source [file join $::flutiou::libdir trash arc.tcl]
#    ttk::style theme use arc
#    . configure -background [ttk::style lookup arc -background {} white]
#
#} elseif { $use == "def"} {
#    ttk::style theme use default
#    . configure -background [ttk::style lookup default -background {} white]
#} elseif { $use == "alt"} {
#    ttk::style theme use alt
#    . configure -background [ttk::style lookup alt -background {} white]
#
#} elseif { $use == "no"} {
#    puts "notheme"
#} else {
    source [file join $::flutiou::libdir lib_funkytheme.tcl]
    set themesrc     [file join $::flutiou::libdir  lib_funkytheme src]
    set themedefault [file join $::flutiou::libdir  lib_funkytheme]
    set themehome    [file join $::flutiou::userdir themes]
    set ::funky::theme::default_dir $themedefault
    set ::funky::theme::user_dir    $themehome
    set ::funky::theme::src_dir     $themesrc

    ::funky::theme::create arctic
    #ttk::style theme create Arctic -parent default -settings ::funky::theme::setup
    ttk::style theme use arctic
    . configure -background [ttk::style lookup tests -background {} white]
#}

# custom widgets
source [file join $::flutiou::libdir wid_extrapopup.tcl]
source [file join $::flutiou::libdir wid_extralabel.tcl]
source [file join $::flutiou::libdir wid_funkybutton.tcl]
source [file join $::flutiou::libdir wid_autoscrollbar.tcl]
source [file join $::flutiou::libdir wid_playzone_playing.tcl]
source [file join $::flutiou::libdir wid_volume.tcl]
namespace import ::w::funkybutton::funkybutton
namespace import ::w::extrapopup::extrapopup
namespace import ::w::extralabel::extralabel
namespace import ::w::autoscrollbar::autoscrollbar

# ui layout
source [file join $::flutiou::libdir lay.tcl]
source [file join $::flutiou::libdir lay_menubar.tcl]
source [file join $::flutiou::libdir lay_statusbar.tcl]
source [file join $::flutiou::libdir lay_playzone.tcl]
source [file join $::flutiou::libdir lay_browse.tcl]
source [file join $::flutiou::libdir lay_browse_files.tcl]
source [file join $::flutiou::libdir lay_browse_collection.tcl]
source [file join $::flutiou::libdir lay_selector.tcl]

# form windows
source [file join $::flutiou::libdir form_configure.tcl]

# ui procs and libs
source [file join $::flutiou::libdir fun_browse_files.tcl]
source [file join $::flutiou::libdir fun_playzone.tcl]
source [file join $::flutiou::libdir lib_filters.tcl]
source [file join $::flutiou::libdir lib_funkytheme.tcl]

proc ::flutiou::setup_imgs {} {
    set imgsdir [file join $::flutiou::libdir lib_icons]
    array set ::flutiou::images {}
    foreach f [glob -directory $imgsdir xicon-*.png] {
        set img [string replace [file tail [file rootname $f]] 0 5]
        set ::flutiou::images($img) [image create photo -file $f -format png]
    }

}

proc ::flutiou::main {} {

    if {$::argc < 1} {puts stderr "ERROR: no player com submited"}


    ############################################################################
    # Setting up the communication with the stdin/stdout of the player command
    # wich sound start at some point "flutio -I"
    #
    puts stderr "start flutio using [lindex $::argv 0]"

    #
    # Our communication pipes with the player
    #
    lassign [chan pipe] pc_in_r  pc_in_w
    lassign [chan pipe] pc_out_r pc_out_w
    lassign [chan pipe] pc_err_r pc_err_w
    set ::flutiou::player_com_out $pc_in_w
    set ::flutiou::player_com_in  $pc_out_r
    set ::flutiou::player_com_err $pc_err_r

    # No buffering, binary, no block
    foreach c [list $pc_out_r $pc_out_w $pc_in_r $pc_in_w $pc_err_r $pc_err_w] \
        {chan configure $c -translation binary -buffering none -blocking 0}

    chan event $::flutiou::player_com_in  readable ::flutiou::player_event
    chan event $::flutiou::player_com_err readable ::flutiou::player_error

    #
    # Spawn our command
    #
    set ::flutiou::player_com_pid \
         [exec flutio -I <@$pc_in_r >@$pc_out_w 2>@$pc_err_w &]

    #
    # ??? chan pipe doc: "To do this, spawn with "2>@" or ">@" redirection
    # operators onto the write side of a pipe, and then immediately close
    # it in the parent." So...
    foreach c [list $pc_err_w $pc_out_w] {chan close $c}
    # It works.
    #

    after 1000 [list puts $pc_in_w "hello"]
    ############################################################################
    # Setting up the ui now
    #

    #
    # Load images, ui::setup_* functions will need them
    #
    set imgsdir [file join $::flutiou::libdir lib_icons]
    array set ::flutiou::images {}
    foreach f [glob -directory $imgsdir xicon-*.png] {
        set img [string replace [file tail [file rootname $f]] 0 5]
        set ::flutiou::images($img) [image create photo -file $f -format png]
    }

    #
    # load filters the playlist treeview requires it
    #
    ::flutiou::collection::filters::setup

    #
    # This is were the actual ui is built
    #
    ::flutiou::ui::setup_window

    #
    # bind everything
    #
    bind all <Escape> exit
    bind all <Return> exit

    $::flutiou::ui::browse::files::layout::table tag bind "directory" \
        <Double-1> ::flutiou::ui::browse::files::procs::user_set_dir

    $::flutiou::ui::playzone::playlist tag bind "music_sample" \
        <Double-1> ::flutiou::play
    $::flutiou::ui::playzone::button_playpause configure \
        -command   ::flutiou::play
    $::flutiou::ui::playzone::button_stop configure \
        -command   ::flutiou::stop
    $::flutiou::ui::playzone::button_skip_backward configure \
        -command   ::flutiou::not_implemented
    $::flutiou::ui::playzone::button_skip_forward  configure \
        -command   ::flutiou::not_implemented

}

#
# Rename exit so we can Save state and clear open things, specialy the player
# command spanwed at startup
#
proc custom_exit {args} {
    if {$::flutiou::player_com_pid > 0} {
        catch {exec kill $::flutiou::player_com_pid}
    }
    original_exit {*}$args
}
rename exit original_exit
rename custom_exit exit

####################################################################################
# user events callbacks
####################################################################################
proc ::flutiou::play {} {

    set index [::flutiou::ui::playzone::procs::get_selection_index]

    set msg_value [dict create revision $::flutiou::playlist_revision index $index]
    set msg [dict create type PLAY value $msg_value]
    #::flutiou::c::cast $msg
}

proc ::flutiou::insert {tracks pos} {
    set msg_data [dict create   \
        tracks   $tracks        \
        pos      $pos           \
        revision $::flutiou::playlist_revision]
    set msg      [dict create type INSERT value $msg_data]
    #::flutiou::c::cast $msg
}

proc ::flutiou::stop {} {
    set msg [dict create type STOP]
    #::flutiou::c::cast $msg
}

proc ::flutiou::update_dirlist {path} {
    set msg [dict create type LISTDIR value $path]
    #::flutiou::c::cast $msg
}

####################################################################################
# network player callbacks
####################################################################################
proc ::flutiou::player_error {} {
    puts "ERROR with: [gets $::flutiou::player_com_err]"
}
proc ::flutiou::player_event {} {
    puts "OUTPUT with: [gets $::flutiou::player_com_in]"

    after 1000 [list puts $::flutiou::player_com_out "lkjlkj"]

    return
    switch [dict get $event type] {
        CONNECTION_ACK {
            ::flutiou::update_dirlist "."
        }
        PLAYLIST_DUMP {
            set ::flutiou::playlist_revision [dict get $event value revision]
            set tracks [dict get $event value tracks]
            ::flutiou::ui::playzone::procs::insert $tracks end
        }
        PLAYLIST_INSERT {
            set ::flutiou::playlist_revision [dict get $event value revision]
            set pos     [dict get $event value pos]
            set tracks  [dict get $event value tracks]
            ::flutiou::ui::playzone::procs::insert $tracks $pos
        }
        DIRECTORY_LIST {
            set listobj [dict get $event value]
            ::flutiou::ui::browse::files::procs::update_dircache $listobj
        }
        CURRENT_TRACK {
            set index [dict get $event value]
            ::flutiou::ui::playzone::update_current $index
        }
        PLAYER_STOPED {
            puts "player stopped!"
            place forget $::flutiou::ui::playzone::playcurrent_canvwidget
        }
        PLAYER_VOLUME {
            puts "player volume!"
            #::extrascale::setvalue [dict get $event value]
        }
        COLLECTION_DUMP {
            set ::flutiou::collection [dict get $event value]
            puts "$::flutiou::collection"
        }
        default {
            puts "unhandled event [dict get $event type]"
        }
    }
}


proc ::flutiou::not_implemented {} {
    puts "not_implemented"
}

#
# Configure a custom exit so we can cleanup
#

#
# The main thing
#
#::flutiou::main

::flutiou::setup_imgs
::flutiou::ui::setup_window
