# Monkeypatch fallbacks to add locale to returned strings
module I18n::Backend::Fallbacks
  def translate(locale, key, options = EMPTY_HASH)
    return super unless options.fetch(:fallback, true)
    return super if options[:fallback_in_progress]
    default = extract_non_symbol_default!(options) if options[:default]

    fallback_options = options.merge(:fallback_in_progress => true, fallback_original_locale: locale)
    I18n.fallbacks[locale].each do |fallback|
      begin
        catch(:exception) do
          result = super(fallback, key, fallback_options)
          result.locale = fallback if locale.to_s != fallback.to_s
          unless result.nil?
            on_fallback(locale, fallback, key, options) if locale.to_s != fallback.to_s
            return result
          end
        end
      rescue I18n::InvalidLocale
        # we do nothing when the locale is invalid, as this is a fallback anyways.
      end
    end

    return if options.key?(:default) && options[:default].nil?

    return super(locale, nil, options.merge(:default => default)) if default
    throw(:exception, I18n::MissingTranslation.new(locale, key, options))
  end
end
