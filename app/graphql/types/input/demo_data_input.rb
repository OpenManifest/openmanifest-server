# frozen_string_literal: true

class Types::Input::DemoDataInput < Types::Base::Input
  argument :gca_count, Integer, required: false
  argument :duty_officer_count, Integer, required: false
  argument :jumper_count, Integer, required: false
  argument :pilot_count, Integer, required: false
  argument :tandem_instructor_count, Integer, required: false
  argument :aff_instructor_count, Integer, required: false
  argument :equipment_inspector_count, Integer, required: false
  argument :coach_count, Integer, required: false
end
