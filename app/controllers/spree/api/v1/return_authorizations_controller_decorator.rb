Spree::Api::V1::ReturnAuthorizationsController.class_eval do
  def my_returns
    @return_authorizations = current_api_user.return_authorizations.includes(:order).order(created_at: :desc).
        page(params[:page]).per(params[:per_page])
    render 'index'
  end

  def my_return
    @return_authorization = current_api_user.return_authorizations.find_by_id(params[:id])
    load_return_items
  end

  private

  def load_return_items
    all_inventory_units = @return_authorization.order.inventory_units
    associated_inventory_units = @return_authorization.return_items.map(&:inventory_unit)
    unassociated_inventory_units = all_inventory_units - associated_inventory_units

    new_return_items = unassociated_inventory_units.map do |new_unit|
      @return_authorization.return_items.build(inventory_unit: new_unit).tap(&:set_default_pre_tax_amount)
    end

    @form_return_items = (@return_authorization.return_items + new_return_items).sort_by(&:inventory_unit_id).uniq
  end
end
