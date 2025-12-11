module Permittable
  extend ActiveSupport::Concern

  included do
    before_action :find_caber_subjects, only: [:create, :update] # rubocop:todo Rails/LexicallyScopedActionFilter
  end

  def find_caber_subjects
    params.values.each do |param|
      if param.is_a?(ActionController::Parameters) && param.has_key?("caber_relations_attributes")
        param["caber_relations_attributes"].transform_values! do |value|
          if value.has_key? "subject"
            subject = case value["subject"]
            when URI::MailTo::EMAIL_REGEXP
              User.find_by!(email: value["subject"])
            when "role::member"
              Role.find_by!(name: :member)
            when "role::public"
              nil
            when /group::([[:digit:]]+)/
              policy_scope(Group).find($1)
            when ""
              raise ActiveRecord::RecordNotFound
            else
              User.find_by!(username: value["subject"])
            end
            value["subject_id"] = subject&.id
            value["subject_type"] = subject&.class&.name
          end
          value
        rescue ActiveRecord::RecordNotFound
          nil
        end
        param["caber_relations_attributes"].compact!
      end
    end
  end
end
