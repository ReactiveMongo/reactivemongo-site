#! /usr/bin/env ruby

require 'liquid'
require 'yaml'

conf_path = ARGV[0]
tmpl_path = ARGV[1]

site = YAML.load_file(conf_path)
tmpl = File.open(tmpl_path)

@template = Liquid::Template.parse(tmpl.read)
puts @template.render('site' => site)
