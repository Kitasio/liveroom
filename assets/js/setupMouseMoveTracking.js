// Setup mouse tracking on the screen element
export function setupMouseMoveTracking(channel) {
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

  channel.on("mouse_move", handleMouseMove);
}

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
export function handleMouseMove(payload) {
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
    dot.className = `absolute z-50 ${color} rounded-full w-4 h-4 pointer-events-none transition-all duration-100`;
    dotsContainer.appendChild(dot);
  } else {
    // If it exists, update the color class (in case it changes)
    // This is a simple way to update color, more robust would be to check if class needs changing
    dot.className = `absolute z-50 ${color} rounded-full w-4 h-4 pointer-events-none transition-all duration-100`;
  }

  // Update the position
  dot.style.left = `${x}px`;
  dot.style.top = `${y}px`;
  dot.style.transform = "translate(-50%, -50%)";
}
