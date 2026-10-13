# frozen_string_literal: true

require "yaml"

# The rename map of GENERALISATION.md §3 (config/vocabulary.yml): finds and rewrites old terms in identifiers.
# bin/check-vocabulary counts them, bin/rename-vocabulary applies a group. The same algorithm is implemented in the
# client (scripts/lib/vocabulary.js); both are tested with the same cases.
#
# An identifier is split into words (snake, kebab, camel, Pascal, SCREAMING); word sequences equal to an entry's `old`
# words are replaced by its `new` words in the style of the identifier. Words are never split inside, so `airplane`
# does not contain `vehicle`.
module Vocabulary
  CONFIG_PATH = File.expand_path("../config/vocabulary.yml", __dir__)
  TOKEN = /[A-Za-z][A-Za-z0-9]*(?:[_-][A-Za-z0-9]+)*/
  # A word of an identifier: an acronym (DutyOfficer), a Capitalised or lowercase word, or digits
  WORD = /[A-Z]+(?![a-z])|[A-Z]?[a-z]+|[0-9]+/

  Entry = Struct.new(:group, :old, :new, keyword_init: true) do
    def old_words = old.split("_")

    def new_words = new.split("_")
  end

  # One word of an identifier and the separator ("", "_" or "-") in front of it
  Part = Struct.new(:text, :sep)

  module_function

  # @return [Hash] allow globs and entries by group
  def config(path = CONFIG_PATH)
    YAML.safe_load_file(path)
  end

  # @param [Array<String>, String, nil] groups none means every group
  # @return [Array<Entry>] longest phrase first
  def entries(groups = nil, config: self.config)
    wanted = Array(groups).map(&:to_s)
    config.fetch("groups").flat_map do |group, items|
      next [] unless wanted.empty? || wanted.include?(group)

      items.map { |item| Entry.new(group: group, old: item.fetch("old"), new: item.fetch("new")) }
    end.sort_by { |entry| -entry.old_words.size }
  end

  # @return [Array<Part>]
  def parts_of(token)
    parts = []
    sep = ""
    token.split(/([_-])/).each do |chunk|
      if chunk.match?(/\A[_-]\z/)
        sep = chunk
        next
      end

      chunk.scan(WORD).each_with_index { |word, index| parts << Part.new(word, index.zero? ? sep : "") }
      sep = ""
    end
    parts
  end

  # Does `entry` start at words[index]? The last old word may carry a plural suffix.
  # @return [Array(Integer, String), nil] the number of words and the plural suffix ("", "s" or "es")
  def match_at(words, index, entry)
    old = entry.old_words
    return nil if index + old.size > words.size

    old.each_with_index do |old_word, offset|
      word = words[index + offset]
      last = offset == old.size - 1
      return nil unless word == old_word || (last && %W(#{old_word}s #{old_word}es).include?(word))
    end
    [old.size, words[index + old.size - 1].delete_prefix(old.last)]
  end

  # @return [Array(Entry, Array), nil] the first entry that matches at words[index], with its match
  def first_match(words, index, entries)
    entries.each do |entry|
      found = match_at(words, index, entry)
      return [entry, found] if found
    end
    nil
  end

  def pluralize(word, suffix)
    return word if suffix.empty?

    return "#{word.delete_suffix('y')}ies" if word.match?(/[^aeiou]y\z/)

    word.end_with?("s", "x", "ch", "sh") ? "#{word}es" : "#{word}s"
  end

  # Rewrites one identifier; returns it unchanged when no entry matches. A lowercase one-word identifier that becomes
  # several words is joined with `single_word_sep` (the backend writes snake_case, the client camelCase).
  def rewrite_token(token, entries, single_word_sep: "_")
    parts = parts_of(token)
    words = parts.map { |part| part.text.downcase }
    screaming = token.include?("_") && !token.match?(/[a-z]/)
    token_sep = (token.include?("_") && "_") || (token.include?("-") && "-") ||
                (parts.size == 1 && token.match?(/\A[a-z]/) ? single_word_sep : "")
    out = []
    index = 0
    changed = false

    while index < parts.size
      entry, found = first_match(words, index, entries)
      unless found
        out << parts[index]
        index += 1
        next
      end

      changed = true
      size, suffix = found
      originals = parts[index, size]
      new_words = entry.new_words.dup
      new_words[-1] = pluralize(new_words.last, suffix)
      joiner = size > 1 ? originals[1].sep : token_sep

      new_words.each_with_index do |word, i|
        sep = i.zero? ? originals.first.sep : joiner
        first_of_token = out.empty? && i.zero?
        cased =
          if screaming then word.upcase
          elsif first_of_token then originals.first.text.match?(/\A[A-Z]/) ? word.capitalize : word
          elsif sep.empty? then word.capitalize
          else word
          end
        out << Part.new(cased, sep)
      end
      index += size
    end

    changed ? out.map { |part| "#{part.sep}#{part.text}" }.join : token
  end

  # Rewrites every identifier in `text`
  def rewrite(text, entries, single_word_sep: "_")
    text.gsub(TOKEN) { |token| rewrite_token(token, entries, single_word_sep: single_word_sep) }
  end

  # Counts the old terms in `text`. @return [Hash{String => Integer}] by the entry's old name
  def scan(text, entries)
    counts = Hash.new(0)
    text.scan(TOKEN) do |token|
      words = parts_of(token).map { |part| part.text.downcase }
      index = 0
      while index < words.size
        entry, = first_match(words, index, entries)
        if entry
          counts[entry.old] += 1
          index += entry.old_words.size
        else
          index += 1
        end
      end
    end
    counts
  end

  # Glob to regexp: `**/` any directories (or none), `**` anything, `*` anything but a slash, `?` one character
  def glob_regexp(glob)
    source = glob.split(%r{(\*\*/|\*\*|\*|\?)}).map do |piece|
      case piece
      when "**/" then "(?:.*/)?"
      when "**" then ".*"
      when "*" then "[^/]*"
      when "?" then "[^/]"
      else Regexp.escape(piece)
      end
    end.join
    Regexp.new("\\A#{source}\\z")
  end

  # True when the path matches one of the allow globs
  def allowed?(path, allow)
    allow.any? { |glob| glob_regexp(glob).match?(path) }
  end
end
