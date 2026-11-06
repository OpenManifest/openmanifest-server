# frozen_string_literal: true

require "rails_helper"
require "tmpdir"

RSpec.describe Industry do
  def write(root, slug, files)
    files.each do |name, content|
      path = root.join(slug, name)
      FileUtils.mkdir_p(path.dirname)
      File.write(path, content.to_yaml)
    end
  end

  def base_template(slug, **extra)
    { "slug" => slug, "name" => slug.capitalize, "description" => "A #{slug}", "icon" => "star", "modules" => {} }.merge(extra)
  end

  around do |example|
    example.run
  ensure
    described_class.reload!
  end

  describe "the shipped templates" do
    it "resolves and validates every template" do
      expect { described_class.reload! }.not_to raise_error
      expect(described_class.all.keys).to include("_aviation", "_water", "_ground", "skydiving", "generic")
    end

    it "offers only the selectable templates" do
      expect(described_class.slugs).to contain_exactly("generic", "skydiving")
      expect(described_class.selectable).to all(have_attributes(base?: false))
    end

    it "gives skydiving the aviation base" do
      expect(described_class.fetch("skydiving").extends).to eq("_aviation")
      expect(described_class.fetch("generic").extends).to be_nil
    end

    it "has terminology and a name for every selectable template" do
      described_class.selectable.each do |industry|
        expect(industry.terminology(:en)).to be_present, "#{industry.slug} has no terminology"
        expect(industry.name).to be_present
      end
    end

    it "raises for an unknown template" do
      expect { described_class.fetch("nope") }.to raise_error(KeyError)
    end

    it "summarises the presets for the picker" do
      expect(described_class.fetch("skydiving").preset_summary).to include("roles" => 11)
    end
  end

  describe "extends" do
    it "overrides a key of the base and inherits the rest" do
      Dir.mktmpdir do |dir|
        root = Pathname.new(dir)
        write(root, "_base", "template.yml" => base_template("_base", "units" => { "distance" => "km", "mass" => "kg" }, "call_schedule_minutes" => [20, 10]),
                             "locales/en.yml" => { "terms" => { "load" => { "one" => "Trip", "other" => "Trips" }, "crew" => { "one" => "Crew", "other" => "Crew" } } })
        write(root, "child", "template.yml" => base_template("child", "extends" => "_base", "units" => { "distance" => "nmi" }, "call_schedule_minutes" => [5]),
                             "locales/en.yml" => { "terms" => { "load" => { "one" => "Flight", "other" => "Flights" } } })

        described_class.reload!(root: root)
        child = described_class.fetch("child")

        expect(child.units).to eq("distance" => "nmi", "mass" => "kg")
        expect(child.call_schedule_minutes).to eq([5])
        expect(child.terminology(:en)).to eq("load" => { "one" => "Flight", "other" => "Flights" }, "crew" => { "one" => "Crew", "other" => "Crew" })
        expect(described_class.selectable.map(&:slug)).to eq(["child"])
      end
    end

    it "rejects a cycle" do
      Dir.mktmpdir do |dir|
        root = Pathname.new(dir)
        write(root, "a", "template.yml" => base_template("a", "extends" => "b"))
        write(root, "b", "template.yml" => base_template("b", "extends" => "a"))

        expect { described_class.reload!(root: root) }.to raise_error(Industry::InvalidTemplate, /cycle/)
      end
    end

    it "rejects a base that does not exist" do
      Dir.mktmpdir do |dir|
        root = Pathname.new(dir)
        write(root, "a", "template.yml" => base_template("a", "extends" => "ghost"))

        expect { described_class.reload!(root: root) }.to raise_error(Industry::InvalidTemplate, /does not exist/)
      end
    end

    it "rejects a template that does not match the schema" do
      Dir.mktmpdir do |dir|
        root = Pathname.new(dir)
        write(root, "a", "template.yml" => base_template("a", "modules" => { "teleportation" => {} }))

        expect { described_class.reload!(root: root) }.to raise_error(Industry::InvalidTemplate)
      end
    end

    it "rejects a template whose slug differs from its directory" do
      Dir.mktmpdir do |dir|
        root = Pathname.new(dir)
        write(root, "a", "template.yml" => base_template("b"))

        expect { described_class.reload!(root: root) }.to raise_error(Industry::InvalidTemplate, /slug/)
      end
    end
  end
end
