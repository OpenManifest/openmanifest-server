# frozen_string_literal: true

require "json_schemer"

# An industry template (GENERALISATION §5): `config/industries/<slug>/` holds template.yml (modules, units, call schedule,
# starting settings), presets.yml (copied into each new operator by Presets::Apply), catalogue.yml (global data seeded
# once) and locales/<locale>.yml (terminology). A template may `extends:` another one: every file is merged over the same
# file of its base (maps deep-merge, lists replace). Templates whose slug starts with `_` are abstract bases and cannot be
# chosen. All templates are loaded and validated at boot, so a broken one fails fast.
class Industry
  ROOT = Rails.root.join("config/industries")
  SCHEMA = JSONSchemer.schema(ROOT.join("schema.json"))
  REQUIRED = %w(slug name description icon modules).freeze
  MODULES = %w(
    destinations activities certifications equipment escorts limits crew multi_vehicle flight_times conditions
    daily_log
  ).freeze

  class InvalidTemplate < StandardError; end

  attr_reader :slug

  class << self
    # @return [Hash{String => Industry}] every template, bases included, resolved
    def all
      @all ||= load_all
    end

    # @return [Industry]
    # @raise [KeyError] for an unknown slug
    def fetch(slug)
      all.fetch(slug.to_s) { raise KeyError, "Unknown industry #{slug.inspect}" }
    end

    # @return [Array<Industry>] the templates an operator can be created from, in name order
    def selectable
      all.values.reject(&:base?).sort_by(&:name)
    end

    def slugs = selectable.map(&:slug)

    # Forget what was loaded (specs that write templates to a temporary directory)
    def reload!(root: ROOT)
      @all = load_all(root)
    end

    private

    def load_all(root = ROOT)
      slugs = Dir[root.join("*/template.yml")].map { |file| File.basename(File.dirname(file)) }
      raw = slugs.index_with { |slug| read_yaml(root.join(slug, "template.yml")) }
      raw.each { |slug, template| validate_file!(slug, template) }
      slugs.index_with { |slug| new(slug, root: root, chain: chain_of(slug, raw)) }.tap do |industries|
        industries.each_value(&:validate!)
      end
    end

    # The slugs from the template itself up to its root base
    def chain_of(slug, raw)
      chain = [slug]
      loop do
        parent = raw.fetch(chain.last)["extends"]
        break if parent.nil?

        raise InvalidTemplate, "#{slug}: extends #{parent}, which does not exist" unless raw.key?(parent)
        raise InvalidTemplate, "#{slug}: extends cycle #{(chain + [parent]).join(' -> ')}" if chain.include?(parent)

        chain << parent
      end
      chain
    end

    def validate_file!(slug, template)
      errors = SCHEMA.validate(template).map { |error| "#{error['data_pointer']}: #{error['error']}" }
      raise InvalidTemplate, "#{slug}/template.yml: #{errors.join('; ')}" if errors.any?
      raise InvalidTemplate, "#{slug}/template.yml: slug is #{template['slug'].inspect}" unless template["slug"] == slug
    end

    def read_yaml(path)
      return {} unless File.exist?(path)

      YAML.safe_load_file(path, aliases: true) || {}
    end
  end

  def initialize(slug, root: ROOT, chain: [slug])
    @slug = slug
    @root = root
    @chain = chain
  end

  def base? = slug.start_with?("_")

  # The merged template.yml
  def template = @template ||= merged("template.yml")

  # What Presets::Apply copies into a new operator: roles, ticket_types, extras, activity_types, inspection_forms, ...
  def presets = @presets ||= merged("presets.yml")

  # Global data seeded once: activity_types and federations (certification bodies)
  def catalogue = @catalogue ||= merged("catalogue.yml")

  %w(name description icon).each { |key| define_method(key) { template[key] } }

  def extends = @chain[1]

  # @return [Hash{String => Hash}] the enabled modules with their configuration (`false` and missing ones are off)
  def modules
    template.fetch("modules", {}).filter_map do |name, config|
      next if config == false

      [name, config.is_a?(Hash) ? config : { "enabled" => config }]
    end.to_h
  end

  def module?(name) = modules.key?(name.to_s)

  def units = template.fetch("units", {})

  def settings = template.fetch("settings", {})

  def vehicle_kinds = template.fetch("vehicle_kinds", [])

  def call_schedule_minutes = template.fetch("call_schedule_minutes", [])

  def crew_roles = template.fetch("crew_roles", [])

  def booking = template.fetch("booking", {})

  # Terms of the industry in a language: `{ "load" => { "one" => "Load", "other" => "Loads" }, "crew" => { ... } }`
  def terminology(locale = :en)
    merged("locales/#{locale}.yml").fetch("terms", {})
  end

  # Names of the permissions and crew roles that presets refer to must exist; modules must be known
  def validate!
    return if base?

    missing = REQUIRED.reject { |key| template[key].present? || template[key] == {} }
    raise InvalidTemplate, "#{slug}: missing #{missing.join(', ')} (after extends)" if missing.any?
  end

  def as_json(*)
    { slug: slug, name: name, description: description, icon: icon, base: extends, modules: modules.keys }
  end

  # How many of each record the presets create, for the picker's preview
  def preset_summary
    presets.slice("roles", "ticket_types", "extras", "activity_types").transform_values(&:size)
  end

  private

  # The file of every template of the chain, the base first, deep-merged
  def merged(file)
    @chain.reverse.map { |slug| self.class.send(:read_yaml, @root.join(slug, file)) }.reduce({}) { |memo, data| deep_merge(memo, data) }
  end

  def deep_merge(base, override)
    base.merge(override) do |_key, old, new|
      old.is_a?(Hash) && new.is_a?(Hash) ? deep_merge(old, new) : new
    end
  end
end
