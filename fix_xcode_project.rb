require 'xcodeproj'

project_path = 'app/ios/Runner.xcodeproj'
file_path = 'Runner/ZZZActivityAttributes.swift'

puts "Opening project at #{project_path}"
project = Xcodeproj::Project.open(project_path)

# Find the file reference, or create it in the 'Runner' group
runner_group = project.main_group['Runner']
if runner_group.nil?
  puts "Error: Could not find 'Runner' group."
  exit 1
end

# Check if file is already there (unlikely given grep result, but good practice)
file_ref = runner_group.files.find { |f| f.path == 'ZZZActivityAttributes.swift' }
if file_ref
  puts "File reference already exists."
else
  puts "Creating file reference for #{file_path}"
  # "Runner/ZZZActivityAttributes.swift" relative to project root? 
  # Usually Runner group path is "Runner". So we add "ZZZActivityAttributes.swift" to it.
  file_ref = runner_group.new_file('ZZZActivityAttributes.swift')
end

# Add to targets
['Runner', 'ZZZWidgetExtension'].each do |target_name|
  target = project.targets.find { |t| t.name == target_name }
  if target
    if target.source_build_phase.files_references.include?(file_ref)
      puts "File already in #{target_name} build phase."
    else
      puts "Adding file to #{target_name} target."
      target.add_file_references([file_ref])
    end
  else
    puts "Warning: Target #{target_name} not found."
  end
end

project.save
puts "Project saved."
