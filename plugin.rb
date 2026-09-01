# frozen_string_literal: true

# name: discourse-authentication-validations
# about: Add custom validations to a User Field to toggle the display of User Fields based on the Signup Modal. This allows you to "chain" User Fields together, so that a User Field is only displayed if a previous User Field has a specific value.
# meta_topic_id: 292547
# version: 0.0.1
# authors: Discourse
# url: TODO
# required_version: 2.7.0

enabled_site_setting :discourse_authentication_validations_enabled

register_asset "stylesheets/common/admin/common.scss"

module ::DiscourseAuthenticationValidations
  PLUGIN_NAME = "discourse-authentication-validations"
end

require_relative "lib/discourse_authentication_validations/engine"

after_initialize do
  add_to_serializer(:user_field, :has_custom_validation) { object.has_custom_validation }
  add_to_serializer(:user_field, :show_values) { object.show_values }
  add_to_serializer(:user_field, :target_user_field_ids) { object.target_user_field_ids }
  add_to_serializer(:user_field, :value_validation_regex) { object.value_validation_regex }

  register_modifier(:admin_user_fields_columns) do |columns|
    columns.push(
      :has_custom_validation,
      :show_values,
      :target_user_field_ids,
      :value_validation_regex,
    )
    columns
  end

  register_modifier(:user_field_required_for_signup) do |required, field, submitted_user_fields|
    DiscourseAuthenticationValidations::RequiredFieldCheck.call(
      required,
      field,
      submitted_user_fields,
    )
  end

  register_modifier(
    :user_field_required_for_update,
  ) do |required, field, submitted_user_fields, user|
    DiscourseAuthenticationValidations::RequiredFieldCheck.call(
      required,
      field,
      submitted_user_fields,
      user,
    )
  end
end
