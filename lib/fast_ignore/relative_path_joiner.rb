# frozen_string_literal: true

class FastIgnore
  module RelativePathJoiner
    def self.prefix_parent_path(parent_relative_path, filename)
      (::Pathname.new(parent_relative_path) + ::Pathname.new(filename)).to_s
    end
  end
end
