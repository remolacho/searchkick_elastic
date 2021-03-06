class Product < ApplicationRecord
  searchkick index_name: "#{Rails.env.to_s}-products"

  has_many :category_products, dependent: :delete_all
  has_many :categories, through: :category_products

  def search_data
    { title: title,
      description: description,
      active: active,
      is_deleted: is_deleted,
      created_at: created_at,
      categories: categories.map(&:name),
      category_ids: category_ids }
  end
end
