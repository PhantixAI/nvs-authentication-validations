# frozen_string_literal: true

RSpec.describe UsersController do
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
  fab!(:batch_field) { Fabricate(:user_field, name: "Batch", requirement: "for_all_users") }

  before do
    UsersController.any_instance.stubs(:honeypot_value).returns(nil)
    UsersController.any_instance.stubs(:challenge_value).returns(nil)
    i_am_field.update!(target_user_field_ids: [batch_field.id])
    SiteSetting.discourse_authentication_validations_enabled = true
    SiteSetting.allow_new_registrations = true
  end

  def signup_params(i_am:, batch:)
    {
      name: "Jane Doe",
      username: "janedoe#{SecureRandom.hex(4)}",
      password: "strongpassword",
      email: "jane#{SecureRandom.hex(4)}@example.com",
      user_fields: {
        i_am_field.id.to_s => i_am,
        batch_field.id.to_s => batch,
      },
    }
  end

  describe "#create" do
    it "still requires Batch when 'I am' is Alumni/Student" do
      expect do
        post "/u.json", params: signup_params(i_am: "Alumni/Student", batch: "")
      end.not_to change { User.count }

      expect(response.parsed_body["success"]).not_to eq(true)
    end

    it "does not require Batch when 'I am' is Dean/Professor/Staff" do
      expect do
        post "/u.json", params: signup_params(i_am: "Dean/Professor/Staff", batch: "")
      end.to change { User.count }.by(1)

      expect(response.parsed_body["success"]).to eq(true)
    end
  end
end
