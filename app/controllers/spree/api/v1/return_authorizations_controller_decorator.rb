Spree::Api::V1::ReturnAuthorizationsController.class_eval do
  def my_returns
    @return_authorizations = current_api_user.return_authorizations.includes(:order).order(created_at: :desc).
        page(params[:page]).per(params[:per_page])
    render 'index'
  end

  def my_return
    @return_authorization = current_api_user.return_authorizations.find_by_id(params[:id])
    @order = @return_authorization.order
    @return_authorization_reason = Spree::ReturnAuthorizationReason.active.where(id: @return_authorization.return_authorization_reason_id).first
    load_associated_return_items
    existing_inventory_ids
  end

  def new_return
    @order = current_api_user.orders.where(id: params[:order_id]).first
    @return_authorization = @order.return_authorizations.build
    load_return_items
    load_return_authorization_reasons
    existing_inventory_ids
    respond_with(@return_authorization, status: 201, default_template: :my_return)
  end

  def user_return
    @order = current_api_user.orders.where(id: params[:order_id]).first
    existing_ids = existing_inventory_ids
    return_item_attributes = params[:return_authorization][:return_items_attributes] if params[:return_authorization]

    if return_item_attributes
      inventory_unit_ids = return_item_attributes.values.map { |x| x[:inventory_unit_id].to_i }.compact
      no_existing_return_items = !inventory_unit_ids.any? { |i| existing_ids.include?(i) }
    end

    @return_authorization = @order.return_authorizations.build(create_return_authorization_params)
    @return_authorization.validate
    if no_existing_return_items && @return_authorization.save
      respond_with(@return_authorization, status: 201, default_template: :show)
    else
      invalid_resource!(@return_authorization)
    end
  end

  private

  def existing_inventory_ids
    @existing_inventory_ids ||= @order.return_authorizations.includes(:inventory_units).map { |x| x.inventory_units.map { |y| y.id  } }.flatten.uniq
  end

  def create_return_authorization_params
    return_authorization_params.merge(user_initiated: true)
  end

  def return_authorization_params
    params.require(:return_authorization).permit(:return_authorization_reason_id, :memo, return_items_attributes: [:inventory_unit_id, :_destroy, :exchange_variant_id])
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
end
