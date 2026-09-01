# frozen_string_literal: true

module ::DiscourseAuthenticationValidations
  module RequiredFieldCheck
    # A field hidden by another field's custom validation (e.g. Branch/Batch hidden because
    # "I am" isn't "Alumni/Student") can't be filled in by the user, so it must not be
    # enforced as required even if it's otherwise marked so.
    #
    # `submitted_user_fields` is the raw `params[:user_fields]` for the current request.
    # `user` is only present on profile updates, where a controlling field (e.g. "I am")
    # may not be part of this particular submission -- in that case we fall back to its
    # already-stored value rather than treating the target field as hidden.
    def self.call(required, field, submitted_user_fields, user = nil)
      return required if !required || !SiteSetting.discourse_authentication_validations_enabled

      controllers =
        UserField
          .where(has_custom_validation: true)
          .select { |controller_field| controller_field.target_user_field_ids.include?(field.id) }
      return required if controllers.empty?

      shown =
        controllers.any? do |controller_field|
          submitted_value = submitted_user_fields&.dig(controller_field.id.to_s)
          submitted_value ||=
            user&.custom_fields&.[]("#{::User::USER_FIELD_PREFIX}#{controller_field.id}")
          controller_field.show_values.include?(submitted_value)
        end

      shown ? required : false
    end
  end
end
