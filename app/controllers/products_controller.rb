class ProductsController < ApplicationController
  def index
    @term = params[:search]
    @products = products.presence || products(partial: true)
    @categories = group_categories
    @similar = similar
  end

  private

  def products(partial: false)
    attr = partial ? options.merge(operator: 'or') : options
    Product.search(@term.presence || '*', attr)
  end

  def options
    { includes: [:categories],
      suggest: true,
      misspellings: {distance: 2},
      page: 1,
      per_page: 10,
      where: {active: true, is_deleted: false},
      order: {created_at: :desc},
      aggs: [:categories],
      fields: ['title^10', 'categories^5', 'description'],
      highlight: {tag: "<strong>"} }
  end

  def group_categories
    return [] unless @products.present?

    @products.aggs['categories']['buckets'].map { | category |
      { name: category['key'], count: category['doc_count'] }
    }
  end

  def similar
    return unless params[:product_id].present?

    prod = Product.find(params[:product_id])

    prod.similar(fields: ['categories'],
                 includes: [:categories],
                 misspellings: {distance: 2},
                 page: params[:page].presence || 1,
                 per_page: 10,
                 where: {active: true, is_deleted: false},
                 order: {created_at: :desc})
  end
end
