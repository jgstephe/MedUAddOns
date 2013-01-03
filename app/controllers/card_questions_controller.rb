class CardQuestionsController < ApplicationController

  #QUESTIONS_TEMPLATE_PATH = "app/assets/javascripts/embedquestions.js"
  QUESTIONS_TEMPLATE_PATH = "public/javascript/embedquestions.js"

  TITLE_1 = "didn't like it"
  TITLE_2 = "it was ok"
  TITLE_3 = "liked it"
  TITLE_4 = "really liked it"
  TITLE_5 = "it was amazing"

  def init
    var = ""

    if UtilHelper.is_card_supported(params)
      begin
        card_id = params[UtilHelper::PARAM_CARDID]
        user_id = UtilHelper.get_user_id(params)

        var = UtilHelper.read_template(QUESTIONS_TEMPLATE_PATH)
        var = UtilHelper.replace_card_id_tag(var, card_id)
        var = UtilHelper.replace_user_id_tag(var, user_id)
        var = UtilHelper.replace_hostname(var)

      rescue   Exception => exception
        logger = QuestionLogger.new(QuestionLogger::LOGFILE)
        logger.log_error(exception.to_s)
        var = ""
      end
    end

    render  js: var
  end

  def show
    @card_id = params[UtilHelper::PARAM_CARDID]
    @user_id = UtilHelper.get_user_id(params)
    @questions = nil
    @runtime_envrironment = RunTimeEnvironment.get_runtime_environment();

    begin
      @questions = QuestionAdminHelper.select_questions_for_card(@card_id)
    rescue Exception => exception
      logger = QuestionLogger.new(QuestionLogger::LOGFILE)
      logger.log_error("CardQuestionsController.show error: " + exception.to_s)
    end
  end

  def save_answer
    response = nil
    answer = nil

    begin
      card_id = params[UtilHelper::PARAM_CARDID].to_i
      user_id = params[UtilHelper::PARAM_USERID]
      question_id = params[UtilHelper::PARAM_QUESTIONID].to_i
      score = params[UtilHelper::PARAM_SCORE].to_i

      # check to see if the user is updating an existing answer or creating a new one
      if(user_id != UtilHelper::UNKNOWN_USER)
        answer = CardQuestionsHelper.get_answer(question_id, user_id.to_i, card_id)
      end

      if(answer == nil)
        answer = Answer.new
        answer.card_id = card_id
        answer.question_id = question_id

        if(user_id != UtilHelper::UNKNOWN_USER)
          answer.user_id  = user_id.to_i
        end
      end

      answer.score = score
      answer.save

      response = AjaxResponse.new(AjaxResponse::SUCCESS, "success")

    rescue Exception => exception
      logger = QuestionLogger.new(QuestionLogger::LOGFILE)
      logger.log_error("CardQuestionsController.save_answer error: " + exception.to_s)
      response = AjaxResponse.new(AjaxResponse::ERROR, exception.to_s)
    end

    render json: response

  end

end
