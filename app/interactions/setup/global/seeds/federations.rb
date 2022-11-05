# frozen_string_literal: true

class Setup::Global::Seeds::Federations < ApplicationInteraction
  steps :create_federations,
        :create_licenses,
        :create_licensed_jump_types

  def create_federations
    ::Federation.import!(
      ::Federation.config.values.map { |federation| federation.slice(:name, :slug) },
      on_duplicate_key_ignore: true
    )
  end

  def create_licenses
    licenses_by_federation = ::Federation.config.map do |slug, federation|
      federation[:licenses].map do |license|
        ::License.new(
          federation: federations_by_slug[slug.to_s],
          name: license[:name],
        )
      end
    end.flatten
    ::License.import!(
      licenses_by_federation,
      on_duplicate_key_ignore: true
    )
  end

  def create_licensed_jump_types
    licensed_jump_types = ::Federation.all.map do |federation|
      federation.licenses.map do |license|
        configuration = ::Federation.config[federation.slug.to_sym][:licenses].find { |l| l[:name] == license.name }
        configuration[:licensed_jump_types].map do |jump_type|
          ::LicensedJumpType.new(
            license: license,
            jump_type: jump_types_by_slug[jump_type.to_s]
          )
        end
      end
    end.flatten
    ::LicensedJumpType.import!(
      licensed_jump_types,
      on_duplicate_key_ignore: true
    )
  end

  private
    def federations_by_slug
      @federations_by_slug ||= ::Federation.all.index_by(&:slug)
    end

    def jump_types_by_slug
      @jump_types_by_slug ||= ::JumpType.all.index_by(&:slug)
    end
end
