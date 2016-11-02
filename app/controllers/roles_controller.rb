class RolesController < ApplicationController
  before_action :set_role, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!
  # GET /roles
  # GET /roles.json
  def index
    @roles = Role.all
    authorize @roles
  end

  def unsubscribe_request
    @roles = Role.where(status: false)
    authorize @roles
  end

  def club_users
    club_period = current_user.president_or_advisor_club_period
    @roles = club_period.club_members
    authorize @roles
  end

  # GET /roles/1
  # GET /roles/1.json
  def show
    authorize @role
  end

  # GET /roles/new
  def new
    @role = Role.new
  end

  # GET /roles/1/edit
  def edit
    authorize @role
  end

  # POST /roles
  # POST /roles.json
  def create
    @role = Role.new(role_params)
    authorize @role
    role_type_president = RoleType.find_by(name: "Başkan")
    if @role.role_type == role_type_president
      has_another_president_role = Role.where(role_type_id: role_type_president.id).map{ |role| role.user.id }.include?(@role.user.id)
      # Başka bir toplulukta başkan mı? kontrolü
      if has_another_president_role
        flash.now[:error] = "#{@role.user.name_surname} başka bir toplulukta başkan. Başkanlık için başka bir üye seçiniz."
        render :new
      else
        all_board_users = ClubBoardOfSupervisory.all + ClubBoardOfDirector.all
        is_member_of_the_board = all_board_users.map{ |club_board| club_board.attributes.except("id", "club_period_id").values.include?(@role.user.id) }.any?
        # Başka bir toplulukta yönetim ya da denetim kurulunda mı? kontrolü
        if is_member_of_the_board
          flash.now[:error] = "#{@role.user.name_surname} başka bir toplulukta yönetim kurulunda ya da denetim kurulunda. Başkanlık için başka bir üye seçiniz."
          render :new
        else
          create_role(@role)
        end
      end
    else
      create_role(@role)
    end
  end

  # PATCH/PUT /roles/1
  # PATCH/PUT /roles/1.json
  def update
    authorize @role
    # if @role.status && @role.explanation
    #   @role.explanation = nil
    #   binding.pry
    # end
    respond_to do |format|
      if @role.update(role_params)
        format.html { redirect_to @role, notice: 'Kullanıcı rolünü başarıyla güncellediniz.' }
        format.json { render :show, status: :ok, location: @role }
      else
        format.html { render :edit }
        format.json { render json: @role.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /roles/1
  # DELETE /roles/1.json
  def destroy
    authorize @role
    @role.destroy
    path = "back".to_sym
    notice_message = "Topluluk üyeliğinden başarıyla ayrıldınız."
    if current_user.admin? && !(request.referer.include? "/clubs/")
      path = roles_url
      notice_message = "Kullanıcıya atanmış rolü başarıyla iptal ettiniz."
    end
    respond_to do |format|
      format.html { redirect_to path, notice: notice_message }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_role
      @role = Role.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def role_params
      params.require(:role).permit(:user_id, :club_period_id, :role_type_id, :status, :explanation)
    end

    def create_role(role)
      respond_to do |format|
        if role.save
          path = "back".to_sym
          notice_message = "Topluluğa başarıyla üye oldunuz."
          if current_user.admin? && !(request.referer.include? "/clubs/")
            path = roles_url
            notice_message = "Kullanıcıya rol ataması başarıyla yapıldı."
          end
          format.html { redirect_to path, notice: notice_message }
          format.json { render :show, status: :created, location: role }
        else
          format.html { render :new }
          format.json { render json: role.errors, status: :unprocessable_entity }
        end
      end
    end
end