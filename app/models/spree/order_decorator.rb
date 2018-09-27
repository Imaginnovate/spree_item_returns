Spree::Order.class_eval do

  scope :shipped, -> { where(shipment_state: 'shipped') }

  def has_returnable_products?
    products.returnable.exists?
  end

  def has_returnable_line_items?
    line_items.any?(&:is_returnable?)
  end

  def any_item_delivered?
    line_items.any?(&:delivered?)
  end
end
