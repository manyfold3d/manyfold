module CarefulTitleize
  def careful_titleize
    # Regex here is from ActiveSupport::Inflector#titleize, but we remove
    # a lot of the preprocessing which discards stuff we want to keep
    gsub(/[_]/, " ").gsub(/\b(?<!\w['â`()])[a-z]/) do |match|
      match.upcase_first
    end
  end
end
