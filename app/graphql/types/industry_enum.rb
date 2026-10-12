# frozen_string_literal: true

# The industry templates an operator can be created from (abstract bases are left out)
class Types::IndustryEnum < Types::Base::Enum
  graphql_name "Industry"
  description "The industry of an operator: chosen when it is created, never changed"

  ::Industry.selectable.each do |industry|
    value industry.slug.upcase, industry.description, value: industry.slug
  end
end
