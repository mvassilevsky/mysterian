class CharactersController < ApplicationController
  before_action :set_character, only: [:show, :edit, :update, :destroy]

  # GET /games/:game_id/characters
  # GET /games/:game_id/characters.json
  def index
    @game = Game.find(params[:game_id])
    @characters = @game.characters
  end

  # GET /games/:game_id/characters/1
  # GET /games/:game_id/characters/1.json
  def show
    if @character.game.owner != current_user && @character.user != current_user
      redirect_to games_url, notice: "That's not your character!"
    end
    @character_abilities = @character.character_abilities
    @all_abilities = Ability.all
  end

  # GET /games/:game_id/characters/new
  def new
    @character = Character.new
  end

  # GET /games/:game_id/characters/1/edit
  def edit
    @character = Character.find(params[:id])
    @game = @character.game
  end

  # POST /games/:game_id/characters
  # POST /games/:game_id/characters.json
  def create
    @character = Character.new(character_params)
    @game = Game.friendly.find(params[:game_id])
    @character.game_id = @game.id
    @player = User.find_by(email: params[:character][:player_email])
    @character.user_id = @player.id unless @player.nil? #change this when we get registration working

    respond_to do |format|
      if @character.save
        if !params[:character][:player_email].blank?
          if @player.nil?
              format.html { redirect_to game_path(@game.slug),
                            notice: 'Character was successfully created, but ' +
                                    'there is no user with that email address.' }
          else
            GameUser.where(user_id: @character.user.id,
                           game_id: @character.game.id).first_or_create
            UserMailer.invite_email(@player, @character.game,
                                    @character).deliver_now
            format.html { redirect_to game_path(@game.slug),
                          notice: 'Character was successfully created.' }
          end
        else
          format.html { redirect_to game_path(@game.slug),
                        notice: 'Character was successfully created.' }
        end
        format.json { render :show, status: :created, location: @character }
      else
        @characters = @game.characters
        format.html { render 'games/show' }
        format.json { render json: @character.errors,
                      status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /games/:game_id/characters/1
  # PATCH/PUT /games/:game_id/characters/1.json
  def update
    @player = User.find_by(email: params[:character][:player_email])

    if @player.nil?
      @character.user_id = nil unless params[:character][:player_email].nil?
      new_user_assigned = false
    else
      @character.user_id = @player.id
      new_user_assigned = true
    end

    respond_to do |format|
      if @character.update(character_params)
        if new_user_assigned
          GameUser.where(user_id: @character.user.id,
                         game_id: @character.game.id).first_or_create
          UserMailer.invite_email(@player, @character.game,
                                  @character).deliver_now
          format.html { redirect_to game_path(@character.game_id),
                        notice: 'Character was successfully updated.' }
        else
          format.html { redirect_to game_path(@character.game_id),
                      notice: 'Character was successfully updated, but ' +
                      'there is no user with that email address.' }
        end
        format.json { render :show, status: :ok,
                    location: game_path(@character.game_id) }
      else
        format.html { render :edit }
        format.json { render json: @character.errors,
                      status: :unprocessable_entity }
      end
    end
  end

  # DELETE /games/:game_id/characters/1
  # DELETE /games/:game_id/characters/1.json
  def destroy
    @character.destroy
    respond_to do |format|
      format.html { redirect_to game_path(@character.game.slug),
                    notice: 'Character was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  # POST /abilities/add
  def add_character_ability
    @character_ability = CharacterAbility.create(character_id: params[:character_id],
                                                 ability_id: params[:ability_id])
    render json: {character_ability_id: @character_ability.id}
  end

  # DELETE /abilities/:id
  def delete_character_ability
    CharacterAbility.delete(params[:id])
    render nothing: true
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_character
      @character = Character.friendly.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def character_params
      params.require(:character).permit(:name, :character_sheet, :game_id,
                                        :player_email)
    end
end
