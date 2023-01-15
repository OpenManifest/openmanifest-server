class Types::Dropzone::MasterLog::MasterLogInput < Types::Base::Input
  argument :notes, String, required: false
  argument :dzso, ID, required: false,
                      prepare: -> (value, ctx) { DropzoneUser.find_by(id: value) }
end
