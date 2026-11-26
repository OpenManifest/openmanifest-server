# frozen_string_literal: true

# Seeds the certification bodies of the industry catalogues with their levels (rank, equivalence key, what they permit)
# and qualifications. Safe to run again: it updates what the catalogue says and leaves the rest alone.
class Setup::Global::Seeds::CertificationBodies < ApplicationInteraction
  steps :create_certification_bodies,
        :create_certification_levels,
        :create_permitted_activities,
        :create_qualifications

  def create_certification_bodies
    ::CertificationBody.config.each do |slug, config|
      body = ::CertificationBody.find_or_initialize_by(slug: slug.to_s)
      body.update!(config.slice(:name, :industry, :verification_provider))
    end
  end

  def create_certification_levels
    each_level do |body, config|
      level = body.certification_levels.find_or_initialize_by(name: config[:name])
      level.update!(config.slice(:rank, :equivalence_key))
    end
  end

  def create_permitted_activities
    each_level do |body, config|
      level = body.certification_levels.find_by!(name: config[:name])
      Array(config[:permitted_activities]).each do |slug|
        activity_type = activity_types_by_slug.fetch(slug.to_s)
        ::PermittedActivity.find_or_create_by!(certification_level: level, activity_type: activity_type)
      end
    end
  end

  def create_qualifications
    ::CertificationBody.config.each do |slug, config|
      Array(config[:qualifications]).each do |qualification|
        body = bodies_by_slug.fetch(slug.to_s)
        body.qualifications.find_or_create_by!(slug: qualification[:slug]) { |record| record.name = qualification[:name] }
      end
    end
  end

  private

  def each_level
    ::CertificationBody.config.each do |slug, config|
      body = bodies_by_slug.fetch(slug.to_s)
      Array(config[:certification_levels]).each { |level| yield body, level }
    end
  end

  def bodies_by_slug
    ::CertificationBody.where(slug: ::CertificationBody.config.keys.map(&:to_s)).index_by(&:slug)
  end

  def activity_types_by_slug
    @activity_types_by_slug ||= ::ActivityType.all.index_by(&:slug)
  end
end
