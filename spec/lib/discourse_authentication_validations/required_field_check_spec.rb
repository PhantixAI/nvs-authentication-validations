# frozen_string_literal: true

RSpec.describe DiscourseAuthenticationValidations::RequiredFieldCheck do
  fab!(:controlling_field) do
    Fabricate(
      :user_field,
      field_type: "dropdown",
      has_custom_validation: true,
      show_values: ["Alumni/Student"],
      target_user_field_ids: [],
    ) do
      user_field_options do
        [
          UserFieldOption.new(value: "Alumni/Student"),
          UserFieldOption.new(value: "Dean/Professor/Staff"),
        ]
      end
    end
  end
  fab!(:target_field) { Fabricate(:user_field, requirement: "for_all_users") }
  fab!(:unrelated_field) { Fabricate(:user_field, requirement: "for_all_users") }

  before do
    controlling_field.update!(target_user_field_ids: [target_field.id])
    SiteSetting.discourse_authentication_validations_enabled = true
  end

  def call(field:, submitted_user_fields:, user: nil)
    described_class.call(field.required?, field, submitted_user_fields, user)
  end

  it "stays required when the field isn't a target of any controlling field" do
    result =
      call(
        field: unrelated_field,
        submitted_user_fields: {
          controlling_field.id.to_s => "Dean/Professor/Staff",
        },
      )

    expect(result).to eq(true)
  end

  it "stays required when the controlling field's submitted value is in show_values" do
    result =
      call(
        field: target_field,
        submitted_user_fields: {
          controlling_field.id.to_s => "Alumni/Student",
        },
      )

    expect(result).to eq(true)
  end

  it "is not required when the controlling field's submitted value isn't in show_values" do
    result =
      call(
        field: target_field,
        submitted_user_fields: {
          controlling_field.id.to_s => "Dean/Professor/Staff",
        },
      )

    expect(result).to eq(false)
  end

  it "is not required when the controlling field wasn't submitted at all" do
    result = call(field: target_field, submitted_user_fields: {})

    expect(result).to eq(false)
  end

  it "falls back to the user's stored value for the controlling field when it's missing from this submission" do
    user = Fabricate(:user)
    user.custom_fields["user_field_#{controlling_field.id}"] = "Alumni/Student"
    user.save_custom_fields

    result = call(field: target_field, submitted_user_fields: {}, user: user)

    expect(result).to eq(true)
  end

  it "does nothing when the field wasn't required to begin with" do
    target_field.update!(requirement: "optional")

    result =
      call(
        field: target_field,
        submitted_user_fields: {
          controlling_field.id.to_s => "Dean/Professor/Staff",
        },
      )

    expect(result).to eq(false)
  end

  it "does nothing when the plugin site setting is disabled" do
    SiteSetting.discourse_authentication_validations_enabled = false

    result =
      call(
        field: target_field,
        submitted_user_fields: {
          controlling_field.id.to_s => "Dean/Professor/Staff",
        },
      )

    expect(result).to eq(true)
  end
end
