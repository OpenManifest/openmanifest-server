# frozen_string_literal: true

class Types::Input::DemoDataInput < Types::BaseInputObject
  argument :gca_count, Integer, required: false
  argument :dzso_count, Integer, required: false
  argument :jumper_count, Integer, required: false
  argument :pilot_count, Integer, required: false
  argument :tandem_instructor_count, Integer, required: false
  argument :aff_instructor_count, Integer, required: false
  argument :rig_inspector_count, Integer, required: false
  argument :coach_count, Integer, required: false
end
