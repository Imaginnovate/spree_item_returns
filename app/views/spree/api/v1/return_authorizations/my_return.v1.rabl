object @return_authorization

attributes *return_authorization_attributes
node(:allow_changes) { @return_authorization.allow_return_item_changes? }
node :line_items do
  @form_return_items.map do |item|
    return_item = item
    inventory_unit = return_item.inventory_unit
    editable ||= inventory_unit.shipped? && @return_authorization.allow_return_item_changes? && !return_item.reimbursement
    if line_item_returnable?(inventory_unit.line_item)
      {
        :id => inventory_unit.variant.id,
        :editable => editable,
        :name => inventory_unit.variant.name,
        :options_text => inventory_unit.variant.options_text,
        :state => inventory_unit.state.humanize,
        :pre_tax_amount => return_item.display_pre_tax_amount,
        :exchange_processed => editable && return_item.exchange_processed?,
      }
    end
  end
end