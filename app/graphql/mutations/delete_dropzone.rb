module Mutations
  class DeleteDropzone < Mutations::BaseMutation
    field :dropzone, Types::DropzoneType, null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = Dropzone.find(id)

      model.destroy
      {dropzone: model}
    end
  end
end