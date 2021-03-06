require 'rails_helper'

RSpec.describe Account::CompaniesController, type: :controller do
  let!(:company) { create(:company) }
  before(:each) { sign_in company.user }
  before(:each) do
    allow_any_instance_of(FullContactCompanyProcessor).to receive(:call_fullcontact_api)
      .and_return({})
  end

  describe "GET #index" do
    it "populates an array of companies" do
      get :index
      expect(assigns(:companies)).to contain_exactly(company)
    end

    it "renders the :index view" do
      get :index
      expect(response).to have_http_status(200)
      expect(response).to render_template(:index)
    end
  end

  describe "GET #show" do
    let!(:comment) do
      create :comment, commentable: company,
                       tenant_id: company.user.tenant.id,
                       user_id:  company.user.id
    end

    it "assigns the requested company to @company" do
      get :show, params: { id: company.id }
      expect(assigns(:company)).to eq(company)
    end

    it "renders the #show view" do
      get :show, params: { id: company.id }
      expect(response).to have_http_status(200)
      expect(response).to render_template(:show)
    end

    it "assigns twitter to a twitter processor" do
      get :show, params: { id: company.id }

      expect(assigns(:twitter)).to be_a(TwitterProcessor)
    end

    context 'contains the comments' do
      render_views
      it 'should contain comment body' do
        get :show, params: { id: company.id }
        expect(response.body).to have_content(comment.body)
      end
    end

    context 'when user sale' do
      render_views
      it 'comment should not contain delete link' do
        get :show, params: { id: company.id }
        expect(response.body).to have_link(href: account_comment_path(comment))
      end
    end

    context 'when user admin' do
      before :each do
        @sale = FactoryBot.create(:user, :sale)
        sign_out company.user
        sign_in @sale
      end
      let!(:sale_company) { create :company, user_id: @sale.id }
      let!(:sale_comment) do
        create :comment, commentable: sale_company,
                         user_id: @sale.id,
                         tenant_id: @sale.tenant_id
      end
      render_views
      it 'comment should contain delete link' do
        get :show, params: { id: sale_company.id }
        expect(response.body).not_to have_link(href: account_comment_path(sale_comment))
      end
    end
  end

  describe "GET #edit" do
    it "assigns the requested company to @company" do
      get :edit, params: { id: company.id }
      expect(assigns(:company)).to eq(company)
    end

    it "renders the #edit view" do
      get :edit, params: { id: company.id }
      expect(response).to have_http_status(200)
      expect(response).to render_template(:edit)
    end
  end

  describe "GET #new" do
    it "initiate empty Company" do
      get :new
      expect(assigns(:company)).to be_a_new(Company)
    end
  end

  describe "POST create" do
    context "with valid attributes" do
      let!(:val_company) { build(:company) }

      it "creates a new company" do
        expect do
          post :create, params: { company: { name: val_company.name,
                                             domain: val_company.domain } }
        end.to change(Company, :count).by(1)
      end

      it "redirects to the all companies" do
        post :create, params: { company: { name: val_company.name,
                                           domain: val_company.domain } }
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(account_company_path(Company.last))
      end

      it "triggers company_domain_worker" do
        expect do
          post :create, params: { company: { name: val_company.name,
                                             domain: val_company.domain } }
        end.to change(CompanyDomainWorker.jobs, :size).by(1)
      end
    end

    context "with invalid attributes" do
      let!(:inval_company) { build(:company, :invalid_domain) }

      it "does not save the new company" do
        expect do
          post :create, params: { company: { name: inval_company.name,
                                             domain: inval_company.domain } }
        end.to_not change(Company, :count)
      end

      it "re-renders the new method" do
        post :create, params: { company: { name: inval_company.name,
                                           domain: inval_company.domain } }
        expect(response).to have_http_status(200)
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PUT update' do
    context "valid attributes" do
      it "located the requested company" do
        put :update, params: { id: company.id,
                               company: { name: company.name,
                                          domain: company.domain } }
        expect(assigns(:company)).to eq(company)
      end

      it "changes company's attributes" do
        put :update, params: { id: company.id,
                               company: { name: 'edited', domain: 'edited.com' } }
        company.reload
        expect(company.name).to eq('edited')
        expect(company.domain).to eq('edited.com')
      end

      it "redirects to the updated company" do
        put :update, params: { id: company.id,
                               company: { name: 'edited', domain: 'edited.com' } }
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(account_company_path)
      end
    end

    context "invalid attributes" do
      let!(:inval_company) { build(:company, :invalid_domain) }

      it "located the requested company" do
        put :update, params: { id: company.id,
                               company: { name: company.name,
                                          domain: company.domain } }
        expect(assigns(:company)).to eq(company)
      end

      it "does not change company's attributes" do
        put :update, params: { id: company.id,
                               company: { name: inval_company.name,
                                          domain: inval_company.domain } }
        company.reload
        expect(company.name).to_not eq(inval_company.name)
        expect(company.domain).to_not eq(inval_company.domain)
      end

      it "re-renders the edit method" do
        put :update, params: { id: company.id,
                               company: { name: inval_company.name,
                                          domain: inval_company.domain } }
        expect(response).to have_http_status(200)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE destroy' do
    it "deletes the company" do
      expect { delete :destroy, params: { id: company.id } }.to change(Company, :count).by(-1)
    end

    it "redirects to company#index" do
      delete :destroy, params: { id: company.id }
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(account_companies_path)
    end
  end

  describe 'GET download' do
    it 'open pdf' do
      get :download, params: { id: company.id }, format: 'pdf'
      expect(response).to have_http_status(200)
    end
  end
end
