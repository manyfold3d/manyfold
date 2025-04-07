# frozen_string_literal: true

Doorkeeper.configure do
  # Change the ORM that doorkeeper will use (requires ORM extensions installed).
  # Check the list of supported ORMs here: https://github.com/doorkeeper-gem/doorkeeper#orms
  orm :active_record

  # This block will be called to check whether the resource owner is authenticated or not.
  resource_owner_authenticator do
    current_user || warden.authenticate!(scope: :user)
  end

  admin_authenticator do |_routes|
    current_user || warden.authenticate!(scope: :user)
  end

  # You can use your own model classes if you need to extend (or even override) default
  # Doorkeeper models such as `Application`, `AccessToken` and `AccessGrant.
  #
  # By default Doorkeeper ActiveRecord ORM uses its own classes:
  #
  # access_token_class "Doorkeeper::AccessToken"
  # access_grant_class "Doorkeeper::AccessGrant"
  # application_class "Doorkeeper::Application"
  #
  # Don't forget to include Doorkeeper ORM mixins into your custom models:
  #
  #   *  ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessToken - for access token
  #   *  ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessGrant - for access grant
  #   *  ::Doorkeeper::Orm::ActiveRecord::Mixins::Application - for application (OAuth2 clients)
  #
  # For example:
  #
  # access_token_class "MyAccessToken"
  #
  # class MyAccessToken < ApplicationRecord
  #   include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessToken
  #
  #   self.table_name = "hey_i_wanna_my_name"
  #
  #   def destroy_me!
  #     destroy
  #   end
  # end

  # Enables polymorphic Resource Owner association for Access Tokens and Access Grants.
  # By default this option is disabled.
  #
  # Make sure you properly setup you database and have all the required columns (run
  # `bundle exec rails generate doorkeeper:enable_polymorphic_resource_owner` and execute Rails
  # migrations).
  #
  # If this option enabled, Doorkeeper will store not only Resource Owner primary key
  # value, but also it's type (class name). See "Polymorphic Associations" section of
  # Rails guides: https://guides.rubyonrails.org/association_basics.html#polymorphic-associations
  #
  # [NOTE] If you apply this option on already existing project don't forget to manually
  # update `resource_owner_type` column in the database and fix migration template as it will
  # set NOT NULL constraint for Access Grants table.
  #
  # use_polymorphic_resource_owner

  # If you are planning to use Doorkeeper in Rails 5 API-only application, then you might
  # want to use API mode that will skip all the views management and change the way how
  # Doorkeeper responds to a requests.
  #
  # api_only

  # Enforce token request content type to application/x-www-form-urlencoded.
  # It is not enabled by default to not break prior versions of the gem.
  #
  # enforce_content_type

  # Authorization Code expiration time (default: 10 minutes).
  #
  # authorization_code_expires_in 10.minutes

  # Access token expiration time (default: 2 hours).
  # If you set this to `nil` Doorkeeper will not expire the token and omit expires_in in response.
  # It is RECOMMENDED to set expiration time explicitly.
  # Prefer access_token_expires_in 100.years or similar,
  # which would be functionally equivalent and avoid the risk of unexpected behavior by callers.
  #
  # access_token_expires_in 2.hours

  # Assign custom TTL for access tokens. Will be used instead of access_token_expires_in
  # option if defined. In case the block returns `nil` value Doorkeeper fallbacks to
  # +access_token_expires_in+ configuration option value. If you really need to issue a
  # non-expiring access token (which is not recommended) then you need to return
  # Float::INFINITY from this block.
  #
  # `context` has the following properties available:
  #
  #   * `client` - the OAuth client application (see Doorkeeper::OAuth::Client)
  #   * `grant_type` - the grant type of the request (see Doorkeeper::OAuth)
  #   * `scopes` - the requested scopes (see Doorkeeper::OAuth::Scopes)
  #   * `resource_owner` - authorized resource owner instance (if present)
  #
  # custom_access_token_expires_in do |context|
  #   context.client.additional_settings.implicit_oauth_expiration
  # end

  # Use a custom class for generating the access token.
  # See https://doorkeeper.gitbook.io/guides/configuration/other-configurations#custom-access-token-generator
  #
  # access_token_generator '::Doorkeeper::JWT'

  # The controller +Doorkeeper::ApplicationController+ inherits from.
  # Defaults to +ActionController::Base+ unless +api_only+ is set, which changes the default to
  # +ActionController::API+. The return value of this option must be a stringified class name.
  # See https://doorkeeper.gitbook.io/guides/configuration/other-configurations#custom-controllers
  #
  # base_controller 'ApplicationController'

  # Reuse access token for the same resource owner within an application (disabled by default).
  #
  # This option protects your application from creating new tokens before old **valid** one becomes
  # expired so your database doesn't bloat. Keep in mind that when this option is enabled Doorkeeper
  # doesn't update existing token expiration time, it will create a new token instead if no active matching
  # token found for the application, resources owner and/or set of scopes.
  # Rationale: https://github.com/doorkeeper-gem/doorkeeper/issues/383
  #
  # You can not enable this option together with +hash_token_secrets+.
  #
  # reuse_access_token

  # In case you enabled `reuse_access_token` option Doorkeeper will try to find matching
  # token using `matching_token_for` Access Token API that searches for valid records
  # in batches in order not to pollute the memory with all the database records. By default
  # Doorkeeper uses batch size of 10 000 records. You can increase or decrease this value
  # depending on your needs and server capabilities.
  #
  # token_lookup_batch_size 10_000

  # Set a limit for token_reuse if using reuse_access_token option
  #
  # This option limits token_reusability to some extent.
  # If not set then access_token will be reused unless it expires.
  # Rationale: https://github.com/doorkeeper-gem/doorkeeper/issues/1189
  #
  # This option should be a percentage(i.e. (0,100])
  #
  # token_reuse_limit 100

  # Only allow one valid access token obtained via client credentials
  # per client. If a new access token is obtained before the old one
  # expired, the old one gets revoked (disabled by default)
  #
  # When enabling this option, make sure that you do not expect multiple processes
  # using the same credentials at the same time (e.g. web servers spanning
  # multiple machines and/or processes).
  #
  # revoke_previous_client_credentials_token

  # Only allow one valid access token obtained via authorization code
  # per client. If a new access token is obtained before the old one
  # expired, the old one gets revoked (disabled by default)
  #
  # revoke_previous_authorization_code_token

  # Require non-confidential clients to use PKCE when using an authorization code
  # to obtain an access_token (disabled by default)
  #
  # force_pkce

  # Hash access and refresh tokens before persisting them.
  # This will disable the possibility to use +reuse_access_token+
  # since plain values can no longer be retrieved.
  #
  # Note: If you are already a user of doorkeeper and have existing tokens
  # in your installation, they will be invalid without adding 'fallback: :plain'.
  #
  # hash_token_secrets
  # By default, token secrets will be hashed using the
  # +Doorkeeper::Hashing::SHA256+ strategy.
  #
  # If you wish to use another hashing implementation, you can override
  # this strategy as follows:
  #
  # hash_token_secrets using: '::Doorkeeper::Hashing::MyCustomHashImpl'
  #
  # Keep in mind that changing the hashing function will invalidate all existing
  # secrets, if there are any.

  # Hash application secrets before persisting them.
  #
  # hash_application_secrets
  #
  # By default, applications will be hashed
  # with the +Doorkeeper::SecretStoring::SHA256+ strategy.
  #
  # If you wish to use bcrypt for application secret hashing, uncomment
  # this line instead:
  #
  # hash_application_secrets using: '::Doorkeeper::SecretStoring::BCrypt'

  # When the above option is enabled, and a hashed token or secret is not found,
  # you can allow to fall back to another strategy. For users upgrading
  # doorkeeper and wishing to enable hashing, you will probably want to enable
  # the fallback to plain tokens.
  #
  # This will ensure that old access tokens and secrets
  # will remain valid even if the hashing above is enabled.
  #
  # This can be done by adding 'fallback: plain', e.g. :
  #
  # hash_application_secrets using: '::Doorkeeper::SecretStoring::BCrypt', fallback: :plain

  # Issue access tokens with refresh token (disabled by default), you may also
  # pass a block which accepts `context` to customize when to give a refresh
  # token or not. Similar to +custom_access_token_expires_in+, `context` has
  # the following properties:
  #
  # `client` - the OAuth client application (see Doorkeeper::OAuth::Client)
  # `grant_type` - the grant type of the request (see Doorkeeper::OAuth)
  # `scopes` - the requested scopes (see Doorkeeper::OAuth::Scopes)
  #
  # use_refresh_token

  # Provide support for an owner to be assigned to each registered application (disabled by default)
  # Optional parameter confirmation: true (default: false) if you want to enforce ownership of
  # a registered application
  # NOTE: you must also run the rails g doorkeeper:application_owner generator
  # to provide the necessary support
  #
  # enable_application_owner confirmation: false

  # Define access token scopes for your provider
  # For more information go to
  # https://doorkeeper.gitbook.io/guides/ruby-on-rails/scopes
  #
  default_scopes :read
  optional_scopes :write

  # Allows to restrict only certain scopes for grant_type.
  # By default, all the scopes will be available for all the grant types.
  #
  # Keys to this hash should be the name of grant_type and
  # values should be the array of scopes for that grant type.
  # Note: scopes should be from configured_scopes (i.e. default or optional)
  #
  # scopes_by_grant_type password: [:write], client_credentials: [:update]

  # Forbids creating/updating applications with arbitrary scopes that are
  # not in configuration, i.e. +default_scopes+ or +optional_scopes+.
  # (disabled by default)
  #
  enforce_configured_scopes

  # Per-user applications
  enable_application_owner confirmation: true
end
