require 'rails_helper'

RSpec.describe SystemAdmin::UsersController, type: :controller do
  let(:system_admin) { create(:user, :system_admin) }
  let(:regular_user) { create(:user) }
  let(:organization) { create(:organization) }

  before do
    organization.organization_users.create!(user: regular_user, role: 'member')
    organization.organization_users.create!(user: system_admin, role: 'owner')
  end

  describe "when user is system admin" do
    before { sign_in system_admin }

    describe "GET #index" do
      it "returns success" do
        get :index
        expect(response).to have_http_status(:success)
        expect(assigns(:users)).to be_present
        expect(assigns(:stats)).to be_present
      end

      it "includes all users" do
        get :index
        expect(assigns(:users)).to include(system_admin, regular_user)
      end

      it "filters by search term" do
        get :index, params: { search: regular_user.first_name }
        expect(assigns(:users)).to include(regular_user)
      end

      it "filters by role" do
        get :index, params: { role: 'system_admin' }
        expect(assigns(:users)).to include(system_admin)
      end
    end

    describe "GET #show" do
      it "returns success" do
        get :show, params: { id: regular_user.id }
        expect(response).to have_http_status(:success)
        expect(assigns(:user)).to eq(regular_user)
        expect(assigns(:user_stats)).to be_present
      end
    end

    describe "GET #new" do
      it "returns success" do
        get :new
        expect(response).to have_http_status(:success)
        expect(assigns(:user)).to be_a(User)
        expect(assigns(:user)).to be_new_record
      end
    end

    describe "POST #create" do
      context "with valid parameters" do
        let(:valid_params) do
          {
            user: {
              first_name: "John",
              last_name: "Doe",
              email: "john.doe@example.com",
              password: "SecurePassword123!",
              password_confirmation: "SecurePassword123!",
              role: "member"
            }
          }
        end

        it "creates a user and redirects" do
          expect {
            post :create, params: valid_params
          }.to change(User, :count).by(1)

          created_user = assigns(:user)
          expect(response).to redirect_to(system_admin_user_path(created_user))
          expect(flash[:notice]).to include("created successfully")
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) do
          {
            user: {
              first_name: "",
              email: "invalid-email",
              password: "short"
            }
          }
        end

        it "does not create a user" do
          expect {
            post :create, params: invalid_params
          }.not_to change(User, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "GET #edit" do
      it "returns success" do
        get :edit, params: { id: regular_user.id }
        expect(response).to have_http_status(:success)
        expect(assigns(:user)).to eq(regular_user)
      end
    end

    describe "PATCH #update" do
      context "with valid parameters" do
        let(:update_params) do
          {
            id: regular_user.id,
            user: {
              first_name: "Updated Name"
            }
          }
        end

        it "updates the user and redirects" do
          patch :update, params: update_params
          regular_user.reload
          expect(regular_user.first_name).to eq("Updated Name")
          expect(response).to redirect_to(system_admin_user_path(regular_user))
          expect(flash[:notice]).to include("updated successfully")
        end
      end

      context "updating password" do
        let(:password_params) do
          {
            id: regular_user.id,
            user: {
              password: "NewSecurePassword123!",
              password_confirmation: "NewSecurePassword123!"
            }
          }
        end

        it "updates the password" do
          patch :update, params: password_params
          regular_user.reload
          expect(regular_user.valid_password?("NewSecurePassword123!")).to be true
        end
      end

      context "with blank password" do
        let(:blank_password_params) do
          {
            id: regular_user.id,
            user: {
              first_name: "Updated",
              password: "",
              password_confirmation: ""
            }
          }
        end

        it "updates other attributes without changing password" do
          original_password = regular_user.encrypted_password
          patch :update, params: blank_password_params
          regular_user.reload
          expect(regular_user.first_name).to eq("Updated")
          expect(regular_user.encrypted_password).to eq(original_password)
        end
      end
    end

    describe "DELETE #destroy" do
      let(:user_to_delete) { create(:user) }

      it "deletes the user and redirects" do
        user_to_delete # Create the user
        expect {
          delete :destroy, params: { id: user_to_delete.id }
        }.to change(User, :count).by(-1)

        expect(response).to redirect_to(system_admin_users_path)
        expect(flash[:notice]).to include("deleted successfully")
      end

      it "prevents deletion of current user" do
        expect {
          delete :destroy, params: { id: system_admin.id }
        }.not_to change(User, :count)

        expect(response).to redirect_to(system_admin_users_path)
        expect(flash[:alert]).to include("cannot delete your own account")
      end

      it "prevents deletion of user with organizations" do
        expect {
          delete :destroy, params: { id: regular_user.id }
        }.not_to change(User, :count)

        expect(response).to redirect_to(system_admin_user_path(regular_user))
        expect(flash[:alert]).to include("belongs to organizations")
      end
    end

    describe "PATCH #lock" do
      it "locks the user account" do
        patch :lock, params: { id: regular_user.id }
        regular_user.reload
        expect(regular_user.access_locked?).to be true
        expect(response).to redirect_to(system_admin_user_path(regular_user))
        expect(flash[:notice]).to include("locked successfully")
      end
    end

    describe "PATCH #unlock" do
      before { regular_user.lock_access! }

      it "unlocks the user account" do
        patch :unlock, params: { id: regular_user.id }
        regular_user.reload
        expect(regular_user.access_locked?).to be false
        expect(response).to redirect_to(system_admin_user_path(regular_user))
        expect(flash[:notice]).to include("unlocked successfully")
      end
    end

    describe "PATCH #confirm" do
      let(:unconfirmed_user) { create(:user, confirmed_at: nil) }

      it "confirms the user account" do
        patch :confirm, params: { id: unconfirmed_user.id }
        unconfirmed_user.reload
        expect(unconfirmed_user.confirmed?).to be true
        expect(response).to redirect_to(system_admin_user_path(unconfirmed_user))
        expect(flash[:notice]).to include("confirmed successfully")
      end
    end

    describe "GET #invite_organization_owner" do
      it "renders the invitation form" do
        get :invite_organization_owner
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST #send_organization_owner_invitation" do
      context "with valid email" do
        it "creates an invitation and redirects with success" do
          expect {
            post :send_organization_owner_invitation, params: { email: "owner@newcompany.com" }
          }.to change(Invitation, :count).by(1)

          invitation = Invitation.last
          expect(invitation.email).to eq("owner@newcompany.com")
          expect(invitation.role).to eq("organization_owner")
          expect(invitation.organization).to be_nil
          expect(invitation.invited_by).to eq(system_admin)

          expect(response).to redirect_to(system_admin_users_path)
          expect(flash[:notice]).to include("invitation sent to owner@newcompany.com successfully")
        end
      end

      context "with invalid email" do
        it "redirects with error for invalid format" do
          expect {
            post :send_organization_owner_invitation, params: { email: "invalid-email" }
          }.not_to change(Invitation, :count)

          expect(response).to redirect_to(invite_organization_owner_system_admin_users_path)
          expect(flash[:alert]).to eq("Please provide a valid email address.")
        end

        it "redirects with error for blank email" do
          expect {
            post :send_organization_owner_invitation, params: { email: "" }
          }.not_to change(Invitation, :count)

          expect(response).to redirect_to(invite_organization_owner_system_admin_users_path)
          expect(flash[:alert]).to eq("Please provide a valid email address.")
        end
      end

      context "with existing user email" do
        let(:existing_user) { create(:user, email: "existing@example.com") }

        it "redirects with error" do
          existing_user # Create the user
          expect {
            post :send_organization_owner_invitation, params: { email: "existing@example.com" }
          }.not_to change(Invitation, :count)

          expect(response).to redirect_to(invite_organization_owner_system_admin_users_path)
          expect(flash[:alert]).to eq("A user with this email address already exists.")
        end
      end
    end
  end

  describe "when user is not system admin" do
    before { sign_in regular_user }

    it "redirects to root path" do
      get :index
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end
  end

  describe "when user is not authenticated" do
    it "redirects to sign in" do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "defensive programming for current_user type" do
    before do
      # Mock authentication to be successful but current_user returns a Hash instead of User object
      allow(controller).to receive(:authenticate_user!).and_return(true)
      allow(controller).to receive(:current_user).and_return({ 'id' => 1, 'role' => 'system_admin' })
      allow(controller).to receive(:user_signed_in?).and_return(true)
    end

    it "handles current_user being a Hash instead of User object" do
      get :index
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end
  end
end
