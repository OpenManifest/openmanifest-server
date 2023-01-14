require 'rails_helper'

describe 'Application Loading' do
  describe 'Zeitwerk' do
    it 'eager loads all files' do
      expect { Zeitwerk::Loader.eager_load_all }.not_to raise_error
    end
  end

  describe 'GraphQL' do
    it 'has a valid schema' do
      expect { GraphQL::Schema::Printer.print_schema(DzSchema) }.not_to raise_error
    end
  end
end
