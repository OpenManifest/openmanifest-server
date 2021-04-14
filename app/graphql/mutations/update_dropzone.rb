module Mutations
  class UpdateDropzone < Mutations::BaseMutation
    field :dropzone, Types::DropzoneType, null: true

    argument :id, Int, required: true
    argument :attributes, Types::Input::DropzoneInput, required: true
    
    def resolve(attributes:, id:)
      model = Dropzone.find(id)

      if model.update(attributes.to_h)
        {dropzone: model}
      else
        model_errors!(model)
      end
    end
  end
end