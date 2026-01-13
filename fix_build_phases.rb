require 'xcodeproj'

project_path = 'app/ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Runner' }

# Find 'Thin Binary' phase
thin_binary_phase = target.build_phases.find { |p| p.display_name == 'Thin Binary' }

if thin_binary_phase
  puts "Found Thin Binary phase at index #{target.build_phases.index(thin_binary_phase)}"
  # Remove it
  target.build_phases.delete(thin_binary_phase)
  # Add it to the end
  target.build_phases << thin_binary_phase
  puts "Moved Thin Binary to the end (index #{target.build_phases.index(thin_binary_phase)})"
  project.save
  puts "Project saved."
else
  puts "Thin Binary phase not found."
end
