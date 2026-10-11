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
    Operator.find_each do |operator|
      context = ApplicationInteraction::SystemContext.new(operator)
      # Loads of days before the operator's today (its own day, not the server's)
      operator.loads.where.not(state: %i(cancelled landed)).where(load_date: ...operator.today).each do |load|
        if load.dispatch_at
          compose(::Manifest::FinalizeLoad, access_context: context, load: load)
        else
          compose(::Manifest::CancelLoad, access_context: context, load: load)
        end
      end
    end
  end
end
