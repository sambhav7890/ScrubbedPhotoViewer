#
# Be sure to run `pod lib lint ScrubbedPhotoViewer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'ScrubbedPhotoViewer'
    s.version          = '0.1.0'
    s.summary          = 'A photoviewer with a scrubbing bar with thumbnails.'

    s.description      = <<-DESC
    This description is used to generate tags and improve search results.
    * Think: What does it do? Why did you write it? What is the focus?
    * Try to keep it short, snappy and to the point.
    * Write the description between the DESC delimiters below.
    * Finally, don't worry about the indent, CocoaPods strips it!
    DESC

    s.homepage         = 'https://github.com/sambhav7890/ScrubbedPhotoViewer'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'sambhav7890' => 'sambhav7890@gmail.com' }
    s.source           = { :git => 'https://github.com/sambhav7890/ScrubbedPhotoViewer.git', :tag => s.version.to_s }

    s.ios.deployment_target = '9.0'

	s.source_files = 'ScrubbedPhotoViewer/Classes/**/ScrubbedPhotoViewer.swift'
	s.frameworks = 'UIKit'
	s.ios.deployment_target = '9.0'

end
