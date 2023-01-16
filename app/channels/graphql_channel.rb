class GraphqlChannel < ApplicationCable::Channel
  def subscribed
    # Store all GraphQL subscriptions the consumer is listening for on this channel
    @subscription_ids = []
  end

  def execute(data)
    query = data["query"]
    variables = ensure_hash(data["variables"])
    operation_name = data["operationName"]

    puts "###### ActionCable ######"
    puts "Current Resource #{context[:current_resource].id}"

    result = DzSchema.execute(
      query: query,
      context: context,
      variables: variables,
      operation_name: operation_name,
    )

    payload = {
      result: result.to_h,
      more: result.subscription?,
    }

    # Append the subscription id
    @subscription_ids << result.context[:subscription_id] if result.context[:subscription_id]

    transmit(payload)
  end

  def unsubscribed
    # Delete all of the consumer's subscriptions from the GraphQL Schema
    @subscription_ids.each do |sid|
      DzSchema.subscriptions.delete_subscription(sid)
    end
  end

  private

  def current_resource
    client = params["client"]
    uid = params["uid"]
    access_token = params["access-token"]
    user = User.find_by(email: uid)
    return nil unless user
    return nil unless user.valid_token?(access_token, client)
    user
  end

  def access_context
    return nil unless current_resource
    AccessContext::CurrentUser.for(current_resource)
  end

  def context
    @context ||= {
      channel: self,
      access_context: access_context,
      current_resource: current_resource,
    }
  end

  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end
end
