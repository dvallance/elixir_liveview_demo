defmodule GamesWeb.ChatView do
  use GamesWeb, :view

  def render_message(%Games.Chat.Message{type: :text} = message) do
    content_tag(:div, class: "chat__message") do
      [
        content_tag(:span, message.user.name, class: "chat__username"),
        content_tag(:span, raw(" &ndash; "), class: "chat__divider"),
        content_tag(:span, Keyword.get(message.meta, :text), class: "chat__text")
      ]
    end
  end

  def render_message(%Games.Chat.Message{type: :game_invite} = message) do
    invited_user = Keyword.fetch!(message.meta, :user)

    content_tag(:div, class: "chat__message") do
      [
        user_name_tag(message.user.name),
        content_tag(:span, raw(" &ndash; "), class: "chat__divider"),
        content_tag(:span, class: "chat__text") do
          [
            "Invited ",
            user_name_tag(invited_user.name),
            " to a game.",
            link("Visit Game", to: "/demo/games")
          ]
        end
      ]
    end
  end

  defp user_name_tag(name) do
    content_tag(:span, name, class: "chat__username")
  end
end
