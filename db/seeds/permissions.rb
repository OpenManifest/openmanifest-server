Permission.names.each do |permission|
  Permission.find_or_create_by(name: permission)
end