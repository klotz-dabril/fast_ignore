# frozen-string-literal: true

class FastIgnore
  class Patterns
    attr_reader :from_file
    attr_reader :root
    attr_reader :patterns
    attr_reader :expand_path_with

    def initialize(*patterns, from_file: nil, format: nil, root: nil, allow: false) # rubocop:disable Metrics/MethodLength
      @allow = allow
      root = PathExpander.expand_dir(root) if root

      if from_file
        @from_file = PathExpander.expand_path(from_file, root || '.')
        root ||= ::File.dirname(from_file)
      else
        @patterns = patterns.flatten.flat_map { |string| string.to_s.lines }
      end
      @root = PathExpander.expand_dir(root || '.')
      @format ||= :gitignore
      @expand_path_with = (@root if format == :expand_path)
    end

    def ==(other)
      from_file == other.from_file &&
        @root == other.root &&
        patterns == other.patterns &&
        @expand_path_with == other.expand_path_with
    end
    alias_method :eql?, :==

    def build
      matchers = Array(build_matchers(allow: @allow)).compact

      ::FastIgnore::RuleGroup.new(matchers, @allow)
    end

    def read_patterns
      if from_file
        ::File.exist?(@from_file) ? ::File.readlines(@from_file) : []
      else
        @patterns
      end
    end

    def build_matchers(allow: false) # rubocop:disable Metrics/MethodLength
      matchers = read_patterns.flat_map do |p|
        ::FastIgnore::Builders::ShebangOrGitignore.build(p, allow, expand_path_with: @expand_path_with)
      end

      return if matchers.empty?
      return [::FastIgnore::Matchers::WithinDir.new(matchers, @root)] unless allow

      [
        ::FastIgnore::Matchers::WithinDir.new(matchers, @root),
        ::FastIgnore::Matchers::WithinDir.new(
          ::FastIgnore::GitignoreIncludeRuleBuilder.new(@root).build_as_parent, '/'
        )
      ]
    end
  end
end
