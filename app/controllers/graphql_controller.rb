# frozen_string_literal: true

class GraphqlController < ApplicationController
  include GraphqlDevise::SetUserByToken
  protect_from_forgery with: :null_session, except: [:index, :execute]

  def index
    # render json: DzSchema.to_json
    render plain: GraphQL::Schema::Printer.print_schema(DzSchema)
  end

  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # protect_from_forgery with: :null_session
  def execute
    # Apollo sends the queries in an array when batching is enabled. The data ends up in the _json field of the params variable.
    # see the Apollo Documentation about query batching: https://www.apollographql.com/docs/react/api/link/apollo-link-batch-http/
    result = if params[:_json]
      queries = params[:_json].map do |param|
        {
          query: param[:query],
          operation_name: param[:operationName],
          variables: prepare_variables(param[:variables]),
          context: gql_devise_context(User),
        }
      end
      DzSchema.multiplex(queries)
    else
      DzSchema.execute(
        params[:query],
        operation_name: params[:operationName],
        variables: prepare_variables(params[:variables]),
        context: gql_devise_context(User),
      )
    end

    render json: result, root: false unless performed?
  rescue => e
    raise e unless Rails.env.development?
    handle_error_in_development e
  end

  private
    # Handle variables in form data, JSON body, or a blank value
    def prepare_variables(variables_param)
      case variables_param
      when String
        if variables_param.present?
          JSON.parse(variables_param) || {}
        else
          {}
        end
      when Hash
        variables_param
      when ActionController::Parameters
        variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
      when nil
        {}
      else
        raise ArgumentError, "Unexpected parameter: #{variables_param}"
      end
    end

    def handle_error_in_development(e)
      logger.error e.message
      logger.error e.backtrace.join("\n")

      render json: { errors: [{ message: e.message, backtrace: e.backtrace }], data: {} }, status: 500
    end
end
