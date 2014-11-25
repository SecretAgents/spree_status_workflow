class Spree::Admin::PickupAddressesController < Spree::Admin::ResourceController

  # GET /spree/admin/pickup_addresses
  # GET /spree/admin/pickup_addresses.json
  def index
    @pickup_addresses = Spree::PickupAddress.all
    @pickup_address = Spree::PickupAddress.new
  end

  # GET /spree/admin/pickup_addresses/1
  # GET /spree/admin/pickup_addresses/1.json
  def show
  end

  # GET /spree/admin/pickup_addresses/new
  def new
    @pickup_address = Spree::PickupAddress.new
  end

  # GET /spree/admin/pickup_addresses/1/edit
  def edit
  end

  # POST /spree/admin/pickup_addresses
  # POST /spree/admin/pickup_addresses.json
  def create
    @pickup_address = Spree::PickupAddress.new(pickup_address_params)

    respond_to do |format|
      if @pickup_address.save
        format.html { redirect_to admin_pickup_addresses_path, notice: 'Pickup address was successfully created.' }
        format.json { render action: 'show', status: :created, location: @pickup_address }
      else
        format.html { render action: 'new' }
        format.json { render json: @pickup_address.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /spree/admin/pickup_addresses/1
  # PATCH/PUT /spree/admin/pickup_addresses/1.json
  def update
    respond_to do |format|
      if @pickup_address.update(pickup_address_params)
        format.html { redirect_to admin_pickup_addresses_path, notice: 'Pickup address was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @pickup_address.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /spree/admin/pickup_addresses/1
  # DELETE /spree/admin/pickup_addresses/1.json
  def destroy
    @pickup_address.destroy
    @pickup_addresses = Spree::PickupAddress.all

    respond_to do |format|
      format.js { render 'refresh_table', :locals => {:pickup_addresses => @pickup_addresses} }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pickup_address
      @pickup_address = Spree::PickupAddress.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def pickup_address_params
      params.require(:pickup_address).permit(:address, :link_to_map)
    end
end
