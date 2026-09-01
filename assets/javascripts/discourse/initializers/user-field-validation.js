import EmberObject from "@ember/object";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

export default {
  name: "user-field-validation",
  initialize() {
    withPluginApi((api) => {
      // A field hidden by another field's custom validation (e.g. Branch/Batch hidden
      // because "I am" isn't "Alumni/Student") can't be filled in by the user, so it must
      // not block submission even if it's otherwise marked required. UserFieldValidations
      // sets `display: none` on the field's *wrapper*, not necessarily on `field.element`
      // itself (e.g. a dropdown's `field.element` is the inner <summary> toggle) --
      // `getComputedStyle` only reflects an element's own resolved style, not whether an
      // ancestor is hidden, so it can't detect this. `offsetParent === null` does: it's
      // null whenever the element or any ancestor has `display: none`.
      api.addCustomUserFieldValidationCallback((userField) => {
        if (
          userField.field.element &&
          userField.field.element.offsetParent === null
        ) {
          return EmberObject.create({ ok: true });
        }
      });

      api.addCustomUserFieldValidationCallback((userField) => {
        if (
          userField.field.has_custom_validation &&
          userField.field.value_validation_regex &&
          userField.value
        ) {
          if (
            !new RegExp(userField.field.value_validation_regex).test(
              userField.value
            )
          ) {
            return EmberObject.create({
              failed: true,
              reason: i18n(
                "discourse_authentication_validations.value_validation_error_message",
                {
                  user_field_name: userField.field.name,
                }
              ),
              element: userField.field.element,
            });
          }
        }
      });
    });
  },
};
