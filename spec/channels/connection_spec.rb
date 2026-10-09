# frozen_string_literal: true

require "rails_helper"

# P6.9: the cable connection is authenticated with the devise token credentials (BUG-011, BUG-060)
RSpec.describe ApplicationCable::Connection do
  include ActionCable::Connection::TestCase::Behavior

  tests ApplicationCable::Connection

  let(:user) { create(:user) }
  let(:auth) { user.create_new_auth_token }

  def params_for(headers, **overrides)
    { "access-token" => headers["access-token"], "client" => headers["client"], "uid" => headers["uid"] }.merge(overrides.transform_keys(&:to_s)).compact
  end

  def open_connection(params)
    connect "/subscriptions?#{params.to_query}"
  end

  it "connects a user with a valid token and identifies them" do
    open_connection(params_for(auth))

    expect(connection.current_user).to eq(user)
  end

  it "rejects a wrong token" do
    expect { open_connection(params_for(auth, 'access-token': "not-the-token")) }.to have_rejected_connection
  end

  it "rejects a token of another client id" do
    expect { open_connection(params_for(auth, client: "someone-else")) }.to have_rejected_connection
  end

  it "rejects a token that belongs to another user's uid" do
    other = create(:user)

    expect { open_connection(params_for(auth, uid: other.uid)) }.to have_rejected_connection
  end

  it "rejects a connection without credentials" do
    expect { connect "/subscriptions" }.to have_rejected_connection
    expect { open_connection({ "uid" => user.uid }) }.to have_rejected_connection
  end

  it "connects a user whose uid is not their email (Apple and Facebook accounts)" do
    apple_user = create(:user)
    apple_user.update_columns(provider: "apple", uid: "000123.abcdef.4567")
    headers = apple_user.create_new_auth_token

    open_connection(params_for(headers))

    expect(connection.current_user).to eq(apple_user)
  end

  it "finds the right account when two providers share a uid" do
    twin = create(:user)
    twin.update_columns(provider: "facebook", uid: user.uid)

    open_connection(params_for(auth))

    expect(connection.current_user).to eq(user)
  end
end
