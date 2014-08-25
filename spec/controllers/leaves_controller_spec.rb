require 'rails_helper'

describe LeavesController do
  let!(:staff) { create :staff }

  describe 'GET #index' do
    def do_request
      get :index
    end

    context 'Staff logged in' do
      let!(:leaves) { create_list(:leave, 5, staff: staff)}

      before { expect(controller).to receive :authenticate_user! }

      it 'fetches all leaves date of current staff' do
        sign_in staff

        do_request

        expect(response).to render_template :index
        expect(assigns(:leaves).size).to eq 5
      end
    end

    context 'No user logged' do
      it 'redirects to root, sets alert flash' do
        do_request

        expect(response).to redirect_to new_user_session_path
        expect(flash[:alert]).to_not be_nil
      end
    end
  end

  describe 'GET #new' do
    def do_request
      get :new
    end
    it 'renders template new and assigns new leave' do
      sign_in staff

      do_request

      expect(response).to render_template :new
      expect(assigns(:leave)).to_not be_nil
    end
  end

  describe 'POST #create' do
    context 'Success' do
      let(:leave_days) { [attributes_for(:leave_day)] }
      let(:leave_param) { attributes_for(:leave, leave_days_attributes: leave_days) }
      let(:leave) { Leave.first }
      let(:last_email) { ActionMailer::Base.deliveries.last }

      def do_request
        post :create, leave: leave_param
      end

      it 'creates leave, redirect to list, sets notice flash' do
        sign_in staff
        do_request

        expect(response).to redirect_to leaves_path
        expect(leave.staff).to eq staff
        expect(leave.reload.leave_days.size).to eq 1
        expect(last_email.to).to eq [ENV['EMAIL_NOTIFIER']]
        expect(last_email.body).to have_content 'New leave application'
        expect(last_email.body).to have_content leave.reason
        expect(flash[:notice]).to_not be_nil
      end
    end

    context 'Failed' do
      let(:leave_param) { attributes_for(:leave, date: '', reason: '') }
      let(:leave) { Leave.first }
      def do_request
        post :create, leave: leave_param
      end

      it 'renders template new and sets the alert flash' do
        sign_in staff

        do_request

        expect(response).to render_template :new
        expect(flash[:alert]).to_not be_nil
      end
    end
  end
end
