module SettingsHelper
  def masked_email(email)
    email.gsub(/(?<=^.)[^@]*|(?<=@.).*(?=\.[^.]+$)/, "****")
  end

  def model_count(library: nil)
    scope = policy_scope(Model)
    scope = scope.where(library: library) if library
    scope.count
  end

  def model_file_count(library: nil)
    scope = policy_scope(ModelFile)
    scope = scope.includes(:model).where("models.library": library) if library
    scope.count
  end

  def total_file_size(library: nil)
    scope = policy_scope(ModelFile)
    scope = scope.includes(:model).where("models.library": library) if library
    scope.sum(:size)
  end

  def creator_count
    policy_scope(Creator).local.count
  end

  def collection_count
    policy_scope(Collection).local.count
  end

  def tag_count
    policy_scope(ActsAsTaggableOn::Tag).count
  end

  def user_count
    policy_scope(User).count
  end
end
