module Spree
  class CurrencyController < Spree::StoreController
    before_action :load_currency
    before_action :load_order

    def set
      Spree::Config[:currency] = session[:currency] = params[:currency] if Spree::Config[:allow_currency_change]

      if @order
        update_order!
      end

      respond_to do |format|
        format.json { render json: !@currency.nil? }
        format.html do
          # We want to go back to where we came from!
          redirect_back_or_default(root_path)
        end
      end
    end

    private

    def load_currency
      @currency = supported_currencies.find { |currency| currency.iso_code == params[:currency] }
    end

    def load_order
      @order = current_order
    end

    def update_order!
      @order.update_attributes!(currency: @currency.iso_code)
      @order.update!

      return unless @order.line_items.any?

      # it's important to do this after the order's currency has been changed
      # as the copy_price method in the tweegy repo will automatically update the price of
      # the line item from the variant, and using the order's currency. 
      @order.line_items.each { |line_item| line_item.copy_price; line_item.save! }
    end
  end
end
