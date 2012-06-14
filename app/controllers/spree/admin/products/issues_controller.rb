module Spree
  module Admin
    module Products
      class IssuesController < Spree::Admin::BaseController
        before_filter :load_magazine
        before_filter :load_issue, :only => [:show, :edit, :update]
        before_filter :load_products, :except => [:show, :index]

        def show
          respond_to do |format|
            format.html
            format.pdf do
              addresses_list = @issue.magazine.subscriptions.map {|s| s.ship_address}
              labels = ::Prawn::Labels.new(addresses_list, :type => "Avery5160") do |pdf, address|
                pdf.text "#{address.firstname} #{address.lastname}"
                pdf.text address.address1
                pdf.text address.address2 if address.address2.present?
                pdf.text "#{address.city} (#{address.state_name}) #{address.zipcode}"
              end
              send_data labels.document.render, :filename => "#{@issue.name}.pdf", :type => "application/pdf", disposition: "inline"
            end
          end
        end

        def index 
          @issues = Issue.where(:magazine_id => @magazine.id)
        end

        def update
          if @issue.update_attributes(params[:issue])          
            flash[:notice] = t('issue_updated')
            redirect_to admin_magazine_issue_path(@magazine, @issue)
          else
            flash[:error] = t(:issue_not_updated)
            render :action => :edit
          end
        end

        def new
          @issue = @magazine.issues.build
        end

        def create          
          if @magazine.issues.create(params[:issue])
            flash[:notice] = t('issue_created')
            redirect_to admin_magazine_issues_path(@magazine)
          else
            flash[:error] = t(:issue_not_created)
            render :new
          end
        end

        private

        def load_magazine
          @magazine = Product.find_by_permalink(params[:magazine_id])
          @product = @magazine # useful to display product_tab menu
        end

        def load_issue
          @issue = Issue.find(params[:id])
        end

        def load_products
          @products = Product.unsubscribable.map { |product| [product.name, product.id] }
        end
      end
    end
  end
end