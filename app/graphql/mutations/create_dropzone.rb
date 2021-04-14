module Mutations
  class CreateDropzone < Mutations::BaseMutation
    field :dropzone, Types::DropzoneType, null: true

    argument :attributes, Types::Input::DropzoneInput, required: true

    def resolve(attributes:)
      model = Dropzone.new(attributes.to_h.except(:banner))

      if model.save
        if attributes[:banner] && attributes[:banner].size > 0
          model.banner.attach(data: attributes[:banner].force_encoding("UTF-8"))
        end

        DropzoneUser.create(
          dropzone: model,
          user: context[:current_resource],
          role: :owner
        )
        { dropzone: model }
      else
        model_errors(model)
      end
    end
  end
end