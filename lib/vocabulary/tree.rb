# frozen_string_literal: true

require_relative "../vocabulary"

module Vocabulary
  # The files of a git checkout that the vocabulary tools read and rewrite
  class Tree
    attr_reader :root, :allow

    def initialize(root: Dir.pwd, config: Vocabulary.config)
      @root = root
      @allow = config.fetch("allow")
    end

    # @return [Array<String>] tracked paths relative to the root
    def paths
      @paths ||= IO.popen(["git", "-C", root, "ls-files", "-z"], &:read).split("\0").select { |path| File.file?(File.join(root, path)) }
    end

    def allowed?(path) = Vocabulary.allowed?(path, allow)

    def text?(path)
      File.binread(File.join(root, path), 8000).to_s.count("\0").zero?
    end

    def read(path) = File.read(File.join(root, path), encoding: "UTF-8")

    # Counts per old term, split into hits in files that must be renamed ("pending") and in allowed paths
    # @return [Hash{Symbol => Hash{String => Integer}}] keyed by :pending / :allowed, then by term
    def count(entries)
      counts = { pending: Hash.new(0), allowed: Hash.new(0) }
      by_directory = Hash.new(0)
      paths.each do |path|
        bucket = allowed?(path) ? :allowed : :pending
        hits = Vocabulary.scan(path, entries)
        hits = hits.merge(Vocabulary.scan(read(path), entries)) { |_, a, b| a + b } if text?(path)
        hits.each { |term, n| counts[bucket][term] += n }
        by_directory[path.split("/").first] += hits.values.sum if bucket == :pending
      end
      [counts, by_directory]
    end
  end
end
