# frozen_string_literal: true

RSpec.describe "Discourse Authentication Validation - Required field exemption" do
  let(:signup_page) { PageObjects::Pages::Signup.new }

  fab!(:i_am_field) do
    Fabricate(
      :user_field,
      name: "I am",
      field_type: "dropdown",
      requirement: "for_all_users",
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
  fab!(:batch_field) do
    Fabricate(:user_field, name: "Batch", field_type: "dropdown", requirement: "for_all_users") do
      user_field_options { [UserFieldOption.new(value: "2024")] }
    end
  end

  before do
    i_am_field.update!(target_user_field_ids: [batch_field.id])
    SiteSetting.discourse_authentication_validations_enabled = true
    SiteSetting.allow_new_registrations = true
  end

  def select_user_field(field_name, value)
    select_kit =
      PageObjects::Components::SelectKit.new(
        ".user-field-#{field_name.downcase.gsub(/\s+/, "-")} .select-kit",
      )
    select_kit.expand
    select_kit.select_row_by_value(value)
  end

  it "does not block account creation when the field is hidden by another field's value" do
    signup_page.open
    signup_page.fill_email("staffmember@example.com")
    signup_page.fill_username("staffmember")
    signup_page.fill_password("aSecurePassword923")
    select_user_field(i_am_field.name, "Dean/Professor/Staff")

    expect(page).to have_no_css(".user-field-batch")
    expect(signup_page).to have_valid_username

    signup_page.click_create_account

    expect(page).to have_current_path("/u/account-created")
  end

  it "still blocks account creation when the field is shown and left blank" do
    signup_page.open
    signup_page.fill_email("studentmember@example.com")
    signup_page.fill_username("studentmember")
    signup_page.fill_password("aSecurePassword923")
    select_user_field(i_am_field.name, "Alumni/Student")

    expect(page).to have_css(".user-field-batch")
    expect(signup_page).to have_valid_username

    signup_page.click_create_account

    expect(page).to have_text(I18n.t("js.user_fields.required_select", name: batch_field.name))
    expect(page).to have_current_path("/signup")
  end
end
