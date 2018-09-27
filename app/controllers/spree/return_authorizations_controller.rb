module Spree
  class ReturnAuthorizationsController < StoreController
    before_action :redirect_unauthorized_access, unless: :spree_current_user
    before_action :load_order, only: [:new, :create, :show]
    before_action :load_return_authorization, only: :show
    before_action :load_form_data, only: :show
    before_action :check_for_returnable_products_in_order, only: :new
    before_action :existing_inventory_ids, only: :show

    def index
      @return_authorizations = spree_current_user.return_authorizations.includes(:order).order(created_at: :desc)
    end

    def new
      @return_authorization = @order.return_authorizations.build
      load_form_data_for_new_return
      existing_inventory_ids
    end

    def create
      existing_ids = existing_inventory_ids
      return_item_attributes = params[:return_authorization][:return_items_attributes] if params[:return_authorization]

      if return_item_attributes
        inventory_unit_ids = return_item_attributes.values.map { |x| x[:inventory_unit_id].to_i }.compact
        no_existing_return_items = !inventory_unit_ids.any? { |i| existing_ids.include?(i) }
        # Check whether all inventory units are related to this order or no
        all_inventory_unit_ids = @order.inventory_units.map { |i| i.id }
        no_other_order_inventory_ids = !inventory_unit_ids.any? { |i| all_inventory_unit_ids.exclude?(i) }
        is_valid = no_existing_return_items && no_other_order_inventory_ids
      end

      flash[:error] = 'Invalid items' unless is_valid
      @return_authorization = @order.return_authorizations.build(create_return_authorization_params)

      if is_valid && @return_authorization.save
        respond_with(@return_authorization) do |format|
          format.html do
            flash[:success] = Spree.t(:successfully_created, resource: 'Item return')
            redirect_to return_authorizations_path
          end
        end
      else
        respond_with(@return_authorization) do |format|
          flash.now[:error] = @return_authorization.errors.full_messages.to_sentence unless flash[:error]
          format.html do
            load_form_data_for_new_return
            render action: :new
          end
        end
      end
    end

    def show
    end

    private

    def existing_inventory_ids
      @existing_inventory_ids ||= @order.return_authorizations.includes(:inventory_units).map { |x| x.inventory_units.map { |y| y.id  } }.flatten.uniq
    end

    def create_return_authorization_params
      return_authorization_params.merge(user_initiated: true)
    end

    def load_form_data
      load_associated_return_items
      load_return_authorization_reasons
    end

    def load_form_data_for_new_return
      load_return_items
      load_return_authorization_reasons
    end


    def load_associated_return_items
      @form_return_items = @return_authorization.return_items.sort_by(&:inventory_unit_id).uniq
    end

    # To satisfy how nested attributes works we want to create placeholder ReturnItems for
    # any InventoryUnits that have not already been added to the ReturnAuthorization.
    def load_return_items
      all_inventory_units = @return_authorization.order.inventory_units
      associated_inventory_units = @return_authorization.return_items.map(&:inventory_unit)
      unassociated_inventory_units = all_inventory_units - associated_inventory_units

      new_return_items = unassociated_inventory_units.map do |new_unit|
        @return_authorization.return_items.build(inventory_unit: new_unit).tap(&:set_default_pre_tax_amount)
      end

      @form_return_items = new_return_items.sort_by(&:inventory_unit_id).uniq
    end


    def load_return_authorization_reasons
      @return_authorization_reasons = Spree::ReturnAuthorizationReason.active
    end

    def load_order
      @order = spree_current_user.orders.delivered.find_by(number: params[:order_id])

      unless @order
        flash[:error] = Spree.t('order_not_found')
        redirect_to account_path
      end
    end

    def load_return_authorization
      @return_authorization = @order.return_authorizations.find_by(number: params[:id])

      unless @return_authorization
        flash[:error] = Spree.t('return_authorizations_controller.return_authorization_not_found')
        redirect_to account_path
      end
    end

    def check_for_returnable_products_in_order
      unless @order.has_returnable_products? && @order.has_returnable_line_items?
        flash[:error] = Spree.t('return_authorizations_controller.return_authorization_not_authorized')
        redirect_to account_path
      end
    end

    def return_authorization_params
      params.require(:return_authorization).permit(:return_authorization_reason_id, :memo, return_items_attributes: [:inventory_unit_id, :_destroy, :exchange_variant_id])
    end
  end
end
