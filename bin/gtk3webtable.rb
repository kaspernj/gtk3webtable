#!/usr/bin/env ruby

require "rubygems"
require "gir_ffi"
require "gir_ffi-gtk3"
require "#{File.realpath("#{File.dirname(__FILE__)}/../..")}/knjrbfw/lib/knjrbfw.rb"

Knj.gem_require(:Gtk3assist, "gtk3assist")
Knj.gem_require(:Html_gen, "html_gen")

require "#{File.realpath("#{File.dirname(__FILE__)}/..")}/lib/gtk3webtable.rb"

GirFFI.setup(:WebKit, "3.0")
Gtk.init
gwt = Gtk3webtable.new
Gtk.main