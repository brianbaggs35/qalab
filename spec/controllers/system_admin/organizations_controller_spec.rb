require 'rails_helper'

RSpec.describe SystemAdmin::OrganizationsController, type: :controller do
  let(:user) { create(:user) }
  let(:system_admin) { create(:user, :system_admin) }
  let(:organization) { create(:organization) }
  let(:organization_with_users) { create(:organization) }
  let(:owner) { create(:user) }

  before do
    create(:organization_user, organization: organization_with_users, user: owner, role: 'owner')
  end

  describe "GET #index" do
    context "with system admin" do
      before { sign_in system_admin }

      it "assigns organizations" do
        get :index
        expect(assigns(:organizations)).to be_present
      end

      it "assigns statistics" do
        get :index
        expect(assigns(:stats)).to be_present
        expect(assigns(:stats)).to have_key(:total)
        expect(assigns(:stats)).to have_key(:active)
        expect(assigns(:stats)).to have_key(:inactive)
      end

      it "filters by search term" do
        org1 = create(:organization, name: "Test Organization")
        org2 = create(:organization, name: "Another Company")
        get :index, params: { search: "Test" }
        expect(assigns(:organizations)).to include(org1)
        expect(assigns(:organizations)).not_to include(org2)
      end
    end

    context "with regular user" do
      before { sign_in user }

      it "redirects with access denied" do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET #show" do
    context "with system admin" do
      before { sign_in system_admin }

      it "assigns organization stats" do
        get :show, params: { id: organization.id }
        expect(assigns(:organization_stats)).to be_present
        expect(assigns(:organization_stats)).to have_key(:users_count)
        expect(assigns(:organization_stats)).to have_key(:success_rate)
      end

      it "assigns recent activity" do
        get :show, params: { id: organization.id }
        expect(assigns(:recent_activity)).to be_present
        expect(assigns(:recent_activity)).to have_key(:recent_test_runs)
        expect(assigns(:recent_activity)).to have_key(:recent_test_cases)
      end
    end

    context "with regular user" do
      before { sign_in user }

      it "redirects with access denied" do
        get :show, params: { id: organization.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end

  describe "GET #new" do
    context "with system admin" do
      before { sign_in system_admin }

      it "assigns new organization" do
        get :new
        expect(assigns(:organization)).to be_a_new(Organization)
      end
    end

    context "with regular user" do
      before { sign_in user }

      it "redirects with access denied" do
        get :new
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) { { organization: { name: "New Organization" } } }
    let(:invalid_params) { { organization: { name: "" } } }

    context "with system admin" do
      before { sign_in system_admin }

      context "with valid parameters" do
        it "creates organization" do
          expect {
            post :create, params: valid_params
          }.to change(Organization, :count).by(1)
        end

        it "redirects to organization show page" do
          post :create, params: valid_params
          expect(response).to redirect_to(system_admin_organization_path(Organization.last))
          expect(flash[:notice]).to include("created successfully")
        end

        it "creates organization with owner when user_id provided" do
          params = valid_params.merge(owner_user_id: owner.id)
          post :create, params: params
          organization = Organization.last
          expect(organization.users).to include(owner)
          expect(organization.organization_users.find_by(user: owner).role).to eq("owner")
        end
      end

      context "with invalid parameters" do
        it "does not create organization" do
          expect {
            post :create, params: invalid_params
          }.not_to change(Organization, :count)
        end
      end
    end

    context "with regular user" do
      before { sign_in user }

      it "redirects with access denied" do
        post :create, params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end

  describe "GET #edit" do
    context "with system admin" do
      before { sign_in system_admin }

      it "assigns organization" do
        get :edit, params: { id: organization.id }
        expect(assigns(:organization)).to eq(organization)
      end
    end

    context "with regular user" do
      before { sign_in user }

      it "redirects with access denied" do
        get :edit, params: { id: organization.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end

  describe "PATCH #update" do
    let(:valid_params) { { id: organization.id, organization: { name: "Updated Name" } } }
    let(:invalid_params) { { id: organization.id, organization: { name: "" } } }

    context "with system admin" do
      before { sign_in system_admin }

      context "with valid parameters" do
        it "updates organization" do
          patch :update, params: valid_params
          organization.reload
          expect(organization.name).to eq("Updated Name")
        end

        it "redirects to organization show page" do
          patch :update, params: valid_params
          expect(response).to redirect_to(system_admin_organization_path(organization))
          expect(flash[:notice]).to include("updated successfully")
        end
      end

      context "with invalid parameters" do
        it "does not update organization" do
          original_name = organization.name
          patch :update, params: invalid_params
          organization.reload
          expect(organization.name).to eq(original_name)
        end
      end
    end

    context "with regular user" do
      before { sign_in user }

      it "redirects with access denied" do
        patch :update, params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end

  describe "DELETE #destroy" do
    context "with system admin" do
      before { sign_in system_admin }

      context "organization without users" do
        it "destroys organization" do
          organization_id = organization.id
          expect {
            delete :destroy, params: { id: organization_id }
          }.to change(Organization, :count).by(-1)
        end

        it "redirects to organizations index" do
          delete :destroy, params: { id: organization.id }
          expect(response).to redirect_to(system_admin_organizations_path)
          expect(flash[:notice]).to include("deleted successfully")
        end
      end

      context "organization with users" do
        it "does not destroy organization" do
          expect {
            delete :destroy, params: { id: organization_with_users.id }
          }.not_to change(Organization, :count)
        end

        it "redirects with error message" do
          delete :destroy, params: { id: organization_with_users.id }
          expect(response).to redirect_to(system_admin_organization_path(organization_with_users))
          expect(flash[:alert]).to include("Cannot delete organization with users")
        end
      end
    end

    context "with regular user" do
      before { sign_in user }

      it "redirects with access denied" do
        delete :destroy, params: { id: organization.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end

  describe "POST #add_user" do
    let(:new_user) { create(:user) }

    context "with system admin" do
      before { sign_in system_admin }

      context "with valid user" do
        it "adds user to organization" do
          post :add_user, params: { id: organization.id, user_id: new_user.id, role: "member" }
          expect(organization.users.reload).to include(new_user)
        end

        it "redirects with success message" do
          post :add_user, params: { id: organization.id, user_id: new_user.id, role: "member" }
          expect(response).to redirect_to(system_admin_organization_path(organization))
          expect(flash[:notice]).to include("added as member successfully")
        end
      end

      context "when user already exists in organization" do
        before { create(:organization_user, organization: organization, user: new_user, role: 'member') }

        it "redirects with error message" do
          post :add_user, params: { id: organization.id, user_id: new_user.id }
          expect(response).to redirect_to(system_admin_organization_path(organization))
          expect(flash[:alert]).to include("already a member")
        end
      end
    end

    context "with regular user" do
      before { sign_in user }

      it "redirects with access denied" do
        post :add_user, params: { id: organization.id, user_id: new_user.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end

  describe "DELETE #remove_user" do
    let(:member_user) { create(:user) }

    before do
      create(:organization_user, organization: organization_with_users, user: member_user, role: 'member')
    end

    context "with system admin" do
      before { sign_in system_admin }

      context "removing a member" do
        it "removes user from organization" do
          delete :remove_user, params: { id: organization_with_users.id, user_id: member_user.id }
          expect(organization_with_users.users.reload).not_to include(member_user)
        end

        it "redirects with success message" do
          delete :remove_user, params: { id: organization_with_users.id, user_id: member_user.id }
          expect(response).to redirect_to(system_admin_organization_path(organization_with_users))
          expect(flash[:notice]).to include("removed from organization successfully")
        end
      end

      context "removing last owner" do
        it "does not remove user" do
          delete :remove_user, params: { id: organization_with_users.id, user_id: owner.id }
          expect(organization_with_users.users.reload).to include(owner)
        end

        it "redirects with error message" do
          delete :remove_user, params: { id: organization_with_users.id, user_id: owner.id }
          expect(response).to redirect_to(system_admin_organization_path(organization_with_users))
          expect(flash[:alert]).to include("Cannot remove the last owner")
        end
      end

      context "when user not in organization" do
        let(:other_user) { create(:user) }

        it "redirects with error message" do
          delete :remove_user, params: { id: organization_with_users.id, user_id: other_user.id }
          expect(response).to redirect_to(system_admin_organization_path(organization_with_users))
          expect(flash[:alert]).to include("is not a member")
        end
      end
    end

    context "with regular user" do
      before { sign_in user }

      it "redirects with access denied" do
        delete :remove_user, params: { id: organization_with_users.id, user_id: member_user.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end

  describe "PATCH #change_user_role" do
    let(:member_user) { create(:user) }

    before do
      create(:organization_user, organization: organization_with_users, user: member_user, role: 'member')
    end

    context "with system admin" do
      before { sign_in system_admin }

      context "changing member role" do
        it "updates user role" do
          patch :change_user_role, params: { id: organization_with_users.id, user_id: member_user.id, new_role: "admin" }
          organization_user = organization_with_users.organization_users.find_by(user: member_user)
          expect(organization_user.role).to eq("admin")
        end

        it "redirects with success message" do
          patch :change_user_role, params: { id: organization_with_users.id, user_id: member_user.id, new_role: "admin" }
          expect(response).to redirect_to(system_admin_organization_path(organization_with_users))
          expect(flash[:notice]).to include("role changed to admin successfully")
        end
      end

      context "changing last owner role" do
        it "does not change role" do
          patch :change_user_role, params: { id: organization_with_users.id, user_id: owner.id, new_role: "admin" }
          organization_user = organization_with_users.organization_users.find_by(user: owner)
          expect(organization_user.role).to eq("owner")
        end

        it "redirects with error message" do
          patch :change_user_role, params: { id: organization_with_users.id, user_id: owner.id, new_role: "admin" }
          expect(response).to redirect_to(system_admin_organization_path(organization_with_users))
          expect(flash[:alert]).to include("Cannot change role of the last owner")
        end
      end

      context "when user not in organization" do
        let(:other_user) { create(:user) }

        it "redirects with error message" do
          patch :change_user_role, params: { id: organization_with_users.id, user_id: other_user.id, new_role: "admin" }
          expect(response).to redirect_to(system_admin_organization_path(organization_with_users))
          expect(flash[:alert]).to include("is not a member")
        end
      end
    end

    context "with regular user" do
      before { sign_in user }

      it "redirects with access denied" do
        patch :change_user_role, params: { id: organization_with_users.id, user_id: member_user.id, new_role: "admin" }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end
end