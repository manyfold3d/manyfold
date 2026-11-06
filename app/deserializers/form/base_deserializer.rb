module Form
  class BaseDeserializer
    def initialize(params:, user:, record: nil)
      @params = params
      @user = user
      @record = record
    end

    def deserialize
      raise NotImplementedError
    end

    private

    def caber_relations_attributes(type:)
      @params.require(type).permit(
        :permission_preset,
        caber_relations_attributes: [:id, :subject_type, :subject_id, :permission, :_destroy]
      )
    end

    def resolve_creator(params, attribute = :creator)
      resolve_object(
        params,
        CreatorPolicy::UpdateScope.new(@user, Creator).resolve,
        attribute
      )
    end

    def resolve_collections(params)
      return params unless params[:collection_ids]

      params[:collections] = CollectionPolicy::UpdateScope.new(@user, Collection).resolve.where(public_id: params.delete(:collection_ids))
      params
    end

    def resolve_collection(params, attribute = :collection)
      resolve_object(
        params,
        CollectionPolicy::UpdateScope.new(@user, Collection).resolve,
        attribute
      )
    end

    def resolve_library(params, attribute = :library)
      resolve_object(
        params,
        LibraryPolicy::Scope.new(@user, Library).resolve,
        attribute
      )
    end

    def resolve_file(params, attribute)
      resolve_object(
        params,
        @record.model_files,
        attribute
      )
    end

    def resolve_object(params, scope, attribute)
      if (id = params.delete(attribute))
        params[attribute] = scope.find_param(id)
      elsif (id = params.delete(:"#{attribute}_id"))
        params[attribute] = scope.find(id)
      end
      params
    rescue ActiveRecord::RecordNotFound
      params
    end

    def user_can_set_permissions?
      @user.is_moderator? || (@record && @user&.owns?(@record))
    end
  end
end
