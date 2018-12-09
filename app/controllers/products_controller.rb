class ProductsController < ApplicationController
  load_and_authorize_resource param_method: :product_params
  skip_authorize_resource :only => :index_json
  
  def index 
      @products = if params[:category].present?
                    Product.by_category(params[:category]).page(params.permit![:page]).per(9)
                  else 
                    Product.all.page(params.permit![:page]).per(9)
                  end
    if params[:query].present?
      @products = @products.custom_search(params[:query])
    end
    @products = @products.price_asc.page(params.permit![:page]).per(9) if (params[:field] == "yasui")
    @products = @products.price_desc.page(params.permit![:page]).per(9) if (params[:field] == "takai")
    @products = @products.order_by_time.page(params.permit![:page]).per(9) if params[:field] == "time"
  end
  
  def new
    @product = Product.new
    @product.build_maker
  end
  
  def show
    @reviews = @product.reviews
  end

  def create
    @product = Product.new product_params
    if @product.save
      flash[:success] = "商品を作成させました"
      if URI(request.referer).path == new_review_path
        redirect_to new_review_path
      else
        redirect_to @product
      end
    else
      flash[:danger] = "商品を作成できません"
      render :new
    end
  end

        
    def edit; end
        
    def update
        if @product.update_attributes product_params
          flash[:success] = "商品を更新されました"
          redirect_to products_url
        else
          render :edit
        end
    end
        
    def destroy
        @product.destroy
        flash[:success] = "商品を削除されました"
        redirect_to request.referrer || products_url
    end
    
  def index_json
    term = params[:term]
    @products = Product.all.where("name LIKE :prefix", prefix: "%#{term}%")
    if term
      render json: {"results" => data_for_select_tag(@products) }
    else
      render json: {"results" => []}
    end
  end

  private
  def product_params
    params.require(:product).permit :name, :category, :image, :maker_id
  end

  def data_for_select_tag products
    products.collect do |product|
      { "id" => product.id, "text" => product.name }
    end
  end
end
