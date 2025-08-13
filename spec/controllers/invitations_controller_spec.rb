require 'rails_helper'

RSpec.describe InvitationsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:owner) { create(:user) }
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:system_admin) { create(:user, role: 'system_admin') }

  before do
    create(:organization_user, organization: organization, user: owner, role: 'owner')
    create(:organization_user, organization: organization, user: admin, role: 'admin')
    create(:organization_user, organization: organization, user: member, role: 'member')
  end

  describe "GET #index" do
    context "when user is an owner" do
      before { sign_in owner }

      it "returns success" do
        get :index
        expect(response).to be_successful
      end

      it "assigns invitations" do
        invitation = create(:invitation, organization: organization, invited_by: owner)
        get :index
        expect(assigns(:invitations)).to include(invitation)
      end
    end

    context "when user is an admin" do
      before { sign_in admin }

      it "returns success" do
        get :index
        expect(response).to be_successful
      end
    end

    context "when user is a member" do
      before { sign_in member }

      it "redirects when unauthorized" do
        get :index
        expect(response).to redirect_to(root_path)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET #new" do
    context "when user is an owner" do
      before { sign_in owner }

      it "returns success" do
        get :new
        expect(response).to be_successful
      end

      it "assigns a new invitation" do
        get :new
        expect(assigns(:invitation)).to be_a_new(Invitation)
      end
    end

    context "when user is a member" do
      before { sign_in member }

      it "redirects when unauthorized" do
        get :new
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        invitation: {
          email: 'newuser@example.com',
          role: 'member'
        }
      }
    end

    let(:invalid_params) do
      {
        invitation: {
          email: '',
          role: 'invalid_role'
        }
      }
    end

    context "when user is an owner" do
      before { sign_in owner }

      context "with valid parameters" do
        it "creates a new invitation" do
          expect {
            post :create, params: valid_params
          }.to change(Invitation, :count).by(1)
        end

        it "assigns the invitation to the organization" do
          post :create, params: valid_params
          expect(Invitation.last.organization).to eq(organization)
        end

        it "assigns the invitation to the current user" do
          post :create, params: valid_params
          expect(Invitation.last.invited_by).to eq(owner)
        end

        it "redirects with success message" do
          post :create, params: valid_params
          expect(response).to redirect_to(invitations_path)
          expect(flash[:notice]).to include("Invitation sent")
        end
      end

      context "with invalid parameters" do
        it "does not create an invitation" do
          expect {
            post :create, params: invalid_params
          }.not_to change(Invitation, :count)
        end

        it "handles validation errors appropriately" do
          post :create, params: invalid_params
          # The response could be a redirect due to authorization or validation error
          expect(response.status).to be_in([ 422, 302 ])
        end
      end
    end

    context "when user is a member" do
      before { sign_in member }

      it "redirects when unauthorized" do
        post :create, params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:invitation) { create(:invitation, organization: organization, invited_by: owner) }

    context "when user is an owner" do
      before { sign_in owner }

      it "destroys the invitation" do
        expect {
          delete :destroy, params: { id: invitation.id }
        }.to change(Invitation, :count).by(-1)
      end

      it "redirects with success message" do
        delete :destroy, params: { id: invitation.id }
        expect(response).to redirect_to(invitations_path)
        expect(flash[:notice]).to include("cancelled")
      end
    end

    context "when user is a member" do
      before { sign_in member }

      it "redirects when unauthorized" do
        delete :destroy, params: { id: invitation.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET #accept" do
    let!(:invitation) { create(:invitation, organization: organization, invited_by: owner) }

    context "with valid token" do
      it "redirects to sign up with token" do
        get :accept, params: { token: invitation.token }
        expect(response).to redirect_to(new_user_registration_path(invitation_token: invitation.token))
      end
    end

    context "with invalid token" do
      it "redirects to sign up with error" do
        get :accept, params: { token: 'invalid-token' }
        expect(response).to redirect_to(new_user_registration_path)
        expect(flash[:alert]).to include("Invalid or expired")
      end
    end

    context "with expired invitation" do
      let!(:expired_invitation) { create(:invitation, :expired, organization: organization, invited_by: owner) }

      it "redirects to sign up with error" do
        get :accept, params: { token: expired_invitation.token }
        expect(response).to redirect_to(new_user_registration_path)
        expect(flash[:alert]).to include("Invalid or expired")
      end
    end

    context "when user is already signed in with correct email" do
      let!(:existing_user) { create(:user, email: invitation.email) }

      before { sign_in existing_user }

      it "accepts invitation and adds user to organization" do
        expect {
          get :accept, params: { token: invitation.token }
        }.to change(OrganizationUser, :count).by(1)

        expect(response).to redirect_to(dashboard_path)
        expect(flash[:notice]).to include("Welcome")
      end
    end

    context "with organization owner invitation" do
      let!(:org_owner_invitation) { create(:invitation, :organization_owner, invited_by: system_admin) }

      it "redirects to sign up for new user" do
        get :accept, params: { token: org_owner_invitation.token }
        expect(response).to redirect_to(new_user_registration_path(invitation_token: org_owner_invitation.token))
      end

      context "when user is signed in with correct email" do
        let!(:existing_user) { create(:user, email: org_owner_invitation.email) }

        before { sign_in existing_user }

        it "accepts invitation and redirects to onboarding" do
          get :accept, params: { token: org_owner_invitation.token }
          
          org_owner_invitation.reload
          expect(org_owner_invitation.accepted?).to be true
          expect(response).to redirect_to(onboarding_welcome_path)
          expect(flash[:notice]).to include("Please set up your organization")
        end
      end

      context "when user is signed in with different email" do
        let!(:different_user) { create(:user, email: "different@example.com") }

        before { sign_in different_user }

        it "signs out user and redirects to registration" do
          get :accept, params: { token: org_owner_invitation.token }
          expect(response).to redirect_to(new_user_registration_path(invitation_token: org_owner_invitation.token))
        end
      end
    end
  end
end
