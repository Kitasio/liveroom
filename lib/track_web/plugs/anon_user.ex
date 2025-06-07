defmodule TrackWeb.AnonUser do
  import Plug.Conn

  @adjectives ~w(
    agile ancient angry brave bright busy calm cheerful clever cloudy cold crazy
    curious cute dark eager fancy fast fierce fluffy friendly funny gentle gifted
    giant graceful happy helpful honest icy jolly kind lazy lively loud lucky
    modern mysterious noisy playful polite proud quick quiet rare rough sad salty
    scary shiny short shy silent silly sleepy slow small smart sneaky soft spicy
    strong sweet tall tender tiny tricky warm weak wild wise young
  )

  @nouns ~w(
    alligator antelope badger bear bird buffalo butterfly camel cat cheetah
    chicken chimpanzee cobra cougar cow coyote crab crocodile deer dog dolphin
    donkey dove dragon duck eagle elephant falcon ferret fish flamingo fox frog
    gazelle giraffe goat goose gorilla hamster hawk hedgehog hippo horse hyena
    jaguar jellyfish kangaroo koala lemur leopard lion lizard llama lobster lynx
    meerkat mole monkey moose mouse octopus orca ostrich otter owl ox panda parrot
    peacock pelican penguin pig pigeon porcupine rabbit raccoon ram rat raven
    reindeer rhino rooster seal shark sheep skunk sloth snail snake sparrow squid
    squirrel stork swan tiger toad turkey turtle vulture walrus whale wolf wombat
    woodpecker yak zebra
  )

  def init(args), do: args

  def call(conn, _args) do
    if conn.assigns[:anon_user] do
      conn
    else
      assign(conn, :anon_user, generate_name())
    end
  end

  defp generate_name do
    adjective = Enum.random(@adjectives)
    noun = Enum.random(@nouns)
    "#{adjective}_#{noun}"
  end

  # TODO: Add another random num to string for uniqueness
end
