    INCLUDE  'exec/types.i'

    INCLUDE  'exec/nodes.i'
    INCLUDE  'exec/lists.i'
    INCLUDE  'exec/interrupts.i'
    INCLUDE  'exec/memory.i'
    INCLUDE  'exec/ports.i'
    INCLUDE  'exec/tasks.i'
    INCLUDE  'exec/libraries.i'
    INCLUDE  'exec/devices.i'
    INCLUDE  'exec/io.i'
*   INCLUDE  'exec/exec.i'
    INCLUDE  'exec/alerts.i'
    INCLUDE  'exec/execname.i'

    INCLUDE  'exec/errors.i'
    INCLUDE  'exec/resident.i'

    INCLUDE  'exec/ables.i'
    INCLUDE  'exec/execbase.i'
    INCLUDE  'exec/initializers.i'
    INCLUDE  'exec/strings.i'
*   INCLUDE  'exec/exec_lib.i'

    INCLUDE  'devices/clipboard.i'
    INCLUDE  'devices/console.i'
    INCLUDE  'devices/timer.i'
    INCLUDE  'devices/gameport.i'
    INCLUDE  'devices/keyboard.i'
    INCLUDE  'devices/inputevent.i'
    INCLUDE  'devices/trackdisk.i'
    INCLUDE  'devices/audio.i'		
    INCLUDE  'devices/keymap.i'
    INCLUDE  'devices/bootblock.i'   
    INCLUDE  'devices/parallel.i'
    INCLUDE  'devices/serial.i'
    INCLUDE  'devices/narrator.i'
    INCLUDE  'devices/input.i'
    INCLUDE  'devices/printer.i'

    INCLUDE  'graphics/gfxbase.i'
    INCLUDE  'graphics/text.i'            
    INCLUDE  'graphics/view.i'
    INCLUDE  'graphics/gfx.i'
    INCLUDE  'graphics/rastport.i'
    INCLUDE  'graphics/layers.i'
    INCLUDE  'graphics/gels.i'            
    INCLUDE  'graphics/clip.i'
    INCLUDE  'graphics/regions.i'
    INCLUDE  'graphics/sprite.i'
    INCLUDE  'graphics/copper.i'
    INCLUDE  'graphics/display.i'

*   INCLUDE  'diag/romdiag.i'

    INCLUDE  'hardware/cia.i'
    INCLUDE  'hardware/custom.i'
    INCLUDE  'hardware/intbits.i'
    INCLUDE  'hardware/dmabits.i'
    INCLUDE  'hardware/adkbits.i'
    INCLUDE  'hardware/blit.i'

    INCLUDE  'intuition/intuition.i'

    INCLUDE  'libraries/dos.i'
    INCLUDE  'libraries/dos_lib.i'
    INCLUDE  'libraries/dosextens.i'
    INCLUDE  'libraries/translator.i'
    INCLUDE  'libraries/diskfont.i'

    INCLUDE  'resources/cia.i'
    INCLUDE  'resources/ciabase.i'
    INCLUDE  'resources/disk.i'
    INCLUDE  'resources/misc.i'
    INCLUDE  'resources/potgo.i'

    INCLUDE  'workbench/icon.i'
    INCLUDE  'workbench/startup.i'
    INCLUDE  'workbench/workbench.i'
    INCLUDE  'workbench/workbenchbase.i'

    XDEF     _main
_main: RTS

	 END
