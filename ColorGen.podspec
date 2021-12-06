Pod::Spec.new do |s|
  s.name             = 'ColorGen'
  s.version          = '0.1.0'
  s.summary          = 'A command line tool that converts a simple color definition file into iOS / Android code (Assets Catalog + Constants / XML).'
  s.homepage         = 'https://github.com/horseshoe7/ColorGen'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { "Stephen O'Connor" => 'oconnor.freelance@gmail.com' }
  s.source           = { :git => 'git@github.com:horseshoe7/ColorGen.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/**/*'
end
