require 'rails_helper'

RSpec.describe SystemAdmin::OrganizationsController, type: :controller do
  let(:user) { create(:user) }
  let(:system_admin) { create(:user, :system_admin) }
  let(:organization) { create(:organization) }
  let(:organization_with_users) { create(:organization) }
  let(:owner) { create(:user) }

  before do
    create(:organization_user, organization: organization_with_users, user: owner, role: 'owner')
    # Mock rendering to avoid template issues
    allow(controller).to receive(:render)
  end

  describe "authorization checks" do
    it "redirects non-system admin users" do
      sign_in user
      get :index
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end
  end

  describe "POST #add_user" do
    let(:new_user) { create(:user) }

    context "with system admin" do
      before { sign_in system_admin }

      it "adds user to organization" do
        post :add_user, params: { id: organization.id, user_id: new_user.id, role: "member" }
        expect(organization.users.reload).to include(new_user)
      end

      it "redirects with success message" do
        post :add_user, params: { id: organization.id, user_id: new_user.id, role: "member" }
        expect(response).to redirect_to(system_admin_organization_path(organization))
        expect(flash[:notice]).to include("added as member successfully")
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

  describe "private methods" do
    let(:controller_instance) { described_class.new }

    it "sets organization" do
      allow(controller_instance).to receive(:params).and_return({ id: organization.id })
      controller_instance.send(:set_organization)
      expect(controller_instance.instance_variable_get(:@organization)).to eq(organization)
    end

    it "permits organization params" do
      params = ActionController::Parameters.new(organization: { name: "Test Org", settings: {} })
      allow(controller_instance).to receive(:params).and_return(params)
      permitted = controller_instance.send(:organization_params)
      expect(permitted.permitted?).to be true
      expect(permitted.keys).to include("name")
    end
  end
end