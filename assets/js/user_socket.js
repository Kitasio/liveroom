// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// Bring in Phoenix channels client library:
import { Socket } from "phoenix"

// And connect to the path in "lib/track_web/endpoint.ex". We pass the
// token for authentication. Read below how it should be used.
const socket = new Socket("/socket", { params: { token: window.userToken } })

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/track_web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/track_web/components/layouts/root.html.heex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/track_web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1_209_600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, connect to the socket:
socket.connect()

// Now that you are connected, you can join channels with a topic.
// Let's assume you have a channel with a topic named `room` and the
// subtopic is its id - in this case lobby:
const channel = socket.channel("room:lobby", {})

function throttle(callback, limit) {
  let lastCall = 0;
  return function(...args) {
    const now = Date.now();
    if (now - lastCall >= limit) {
      lastCall = now;
      callback.apply(this, args);
    }
  };
}

// Handle incoming mouse move events from the channel
function handleMouseMove(payload) {
  const { id, x, y, color } = payload;

  // Get the parent container for dots
  const dotsContainer = document.querySelector("#dots");
  if (!dotsContainer) {
    console.error("Dots container not found!");
    return;
  }

  // Try to find an existing dot for this ID
  let dot = document.getElementById(`dot-${id}`);

  if (!dot) {
    // Create a new dot if it doesn't exist
    dot = document.createElement("div");
    dot.id = `dot-${id}`;
    dot.className = `absolute ${color} rounded-full w-4 h-4 pointer-events-none transition-all duration-100`;
    dotsContainer.appendChild(dot);
  } else {
    // If it exists, update the color class (in case it changes)
    // This is a simple way to update color, more robust would be to check if class needs changing
    dot.className = `absolute ${color} rounded-full w-4 h-4 pointer-events-none transition-all duration-100`;
  }

  // Update the position
  dot.style.left = `${x}px`;
  dot.style.top = `${y}px`;
  dot.style.transform = "translate(-50%, -50%)";
}

// Setup mouse tracking on the screen element
function setupMouseMoveTracking(channel) {
  const screen = document.querySelector("#screen");
  if (!screen) {
    console.error("Screen element not found!");
    return;
  }

  // Throttle mouse move events to avoid flooding the channel
  const throttledMouseMove = throttle((e) => {
    channel.push("mouse_move", {
      x: e.clientX,
      y: e.clientY
    });
  }, 24); // Adjust throttle limit as needed

  // Add event listener to the screen
  screen.addEventListener("mousemove", throttledMouseMove);

  console.log("Mouse tracking setup complete.");
}


// Handle mouse events
channel.on("mouse_move", handleMouseMove);

channel.join()
  .receive("ok", resp => {
    console.log("Joined successfully", resp);
    setupMouseMoveTracking(channel); // Setup tracking after successful join
  })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket
