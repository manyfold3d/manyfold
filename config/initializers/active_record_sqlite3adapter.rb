# Taken from https://fractaledmind.github.io/2023/09/07/enhancing-rails-sqlite-fine-tuning/
module RailsExt
  module SQLite3Adapter
    def configure_connection
      super
      @config[:pragmas].each do |key, value|
        raw_execute("PRAGMA #{key} = #{value}", "SCHEMA")
      end
    end
  end
end
