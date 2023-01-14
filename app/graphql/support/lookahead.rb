module Support::Lookahead
  extend ActiveSupport::Concern

  class_methods do
    # Build lookaheads for UPCs by getting a base scope,
    # and the lookahead object, and then returning the
    # joined query.
    # This makes it easier to reuse the lookaheads later
    def self.inherited(child)
      child.include Support::Lookahead::ClassMethods
    end

    def lookahead(&block)
      fail_with_warning unless block
      define_singleton_method(:apply_lookaheads, -> (lookahead, scope) { lookahead.instance_exec(scope, &block) })
    end

    def fail_with_warning
      warn "#{self.class.name}#lookahead requires a block. Usage: lookahead do |scope| ... end"
    end
  end
end
