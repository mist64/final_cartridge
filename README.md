# Final Cartridge

This project is the reverse-engineered and documented Commodore 64 cc65/ca65/cl65 assembly source code of the first bank of the "*Final Cartridge III*".

When assembled, the resulting binary is identical with the 1988-12 version of bank 0 of the original cartridge ROM.

## What is contained?

Bank 0 contains the BASIC and editor extensions, the floppy and tape speeder, fast format, the centronics printer driver, and the monitor. This project does not contain Desktop, the freezer or the BASIC menu bar.

## Building

Create fc3.bin:

    make

Regression test: create fc3.bin and make sure it's identical to the original ROM:

    make test

## Why?

### Reusing Components

The FC3 contained some great components, like the editor and BASIC extensions, and the excellent machine code monitor.

The source was separated into files with minimal dependencies, so they can be included in other projects.

For example:

    make monitor.prg

builds a standalone version of the monitor that can be started with

    sys 32768

### Creating Derivatives

The existing code is a great starting point to create an improved Final Cartridge. Some ideas:

* Replace the floppy speeder with a faster one.
* Disable speeder when it detects non-1541 drives or a high-level emulated drive.
* Add a fast directory function.
* Replace PACK and UNPACK with a different engine.
* Adding disk copy functionality.
* Add "clear all memory" functionality (like "Zero Fill" in freezer)
* Monitor: Support illegal opcodes.
* Monitor: Support screen code.
* Monitor: Optimize "OD" mode for speed.
* Monitor: Allow transfering data between computer and drive.
* Monitor: Allow loading and saving below I/O area.
* Bundle a user-defined set of standard $0801-based programs in ROM.

This can be done without overflowing bank 0, since it contains plenty of code that can be removed, either because it is of little use these days (printer.s, tape code in speeder.s, format.s) or it is only there to support other banks (freezer.s, vectors.s, desktop_helper.s).

Please be aware of the [The Final Replay](http://www.oxyron.de/html/freplay.html) project, which has similar goals, but is based on a clean reimplementation.

## Copyright

The original code is (c) Uwe Stahl and Riska B.V. Home & Personal Computers. The assembly version, the comments, the partitioning into separate files and the linker configuration was done by Michael Steil <mist64@mac.com>; this work is in the public domain.