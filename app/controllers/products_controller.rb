class ProductsController < ApplicationController
  def index
    @term = params[:search]
    @products = products.presence || products(partial: true)
    @categories = group_categories
    # @more_like = more_like
  end

  private

  def products(partial: false)
    attr = partial ? options.merge(operator: 'or') : options
    Product.search(@term.presence || '*', attr)
  end

  def options
    { includes: [:categories],
      misspellings: {distance: 2},
      page: params[:page].presence || 1,
      per_page: 10,
      where: {active: true, is_deleted: false},
      order: {created_at: :desc},
      aggs: [:categories],
      fields: ['title^10', 'categories^5', 'description'] }
  end

  def group_categories
    return [] unless @products.present?

    @products.aggs['categories']['buckets'].map { | category |
      { name: category['key'], count: category['doc_count'] }
    }
  end

  def more_like
    return unless params[:product_id].present?

    prod = Product.find(params[:product_id])
    @more_like = prod.search(query: {
                               mlt: {
                                 like_text: @term,
                                 min_term_freq: 3,
                                 max_query_terms: 35,
                                 boost_terms: 2,
                                 minimum_should_match: '35%'
                               }
                             }, page: params[:page].presence || 1,
                             per_page: 10,
                             where: {active: true, is_deleted: false},
                             order: {created_at: :desc})
  end
end
