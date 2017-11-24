object @return_authorization

attributes *return_authorization_attributes
node(:allow_changes) { @return_authorization.allow_return_item_changes? }
node :return_authorization_reasons do
    if @return_authorization_reasons
        @return_authorization_reasons.map do |reason|
            {
                :id => reason.id,
                :name => reason.name
            }
        end
    end
end
node :line_items do
  @form_return_items.map do |item|
    return_item = item
    inventory_unit = return_item.inventory_unit
    existing = @existing_inventory_ids.detect { |e| e == inventory_unit.id }
    editable ||= inventory_unit.shipped? && @return_authorization.allow_return_item_changes? && !return_item.reimbursement && !existing
    if line_item_returnable?(inventory_unit.line_item)
      {
        :id => inventory_unit.id,
        :variant_id => inventory_unit.variant.id,
        :editable => editable,
        :name => inventory_unit.variant.name,
        :slug => inventory_unit.variant.slug,
        :options_text => inventory_unit.variant.options_text,
        :state => inventory_unit.state.humanize,
        :pre_tax_amount => return_item.display_pre_tax_amount,
        :exchange_processed => editable && return_item.exchange_processed?,
        :reason => @return_authorization_reason&.name
      }
    end
  end
end