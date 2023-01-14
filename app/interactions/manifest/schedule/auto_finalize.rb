class Manifest::Schedule::AutoFinalize < ApplicationInteraction
  steps :auto_finalize

  # Find loads in the past and automatically finalize them.
  # If the loads were dispatched, they will be finalized
  # as landed, and if the loads were never dispatched,
  # they will be cancelled.
  #
  # FIXME: Decide whether or not to auto-cancel all loads
  # that are not finalized
  def auto_finalize
    Dropzone.all.each do |dropzone|
      Time.use_zone(dropzone.time_zone) do
        dropzone.loads.where.not(
          state: %i(cancelled landed)
        ).where(
          created_at: ..DateTime.current.beginning_of_day
        ).each do |load|
          if load.dispatch_at
            compose(
              ::Manifest::FinalizeLoad,
              access_context: ApplicationInteraction::SystemContext.new(dropzone),
              load: load,
            )
          else
            compose(
              ::Manifest::CancelLoad,
              access_context: ApplicationInteraction::SystemContext.new(dropzone),
              load: load,
            )
          end
        end
      end
    end
  end
end
