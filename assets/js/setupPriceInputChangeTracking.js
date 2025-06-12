export function setupPriceInputChangeTracking(channel) {
  const priceInput = document.querySelector("#price-input");
  if (!priceInput) {
    console.error("Price input element not found!");
    return;
  }

  const balance = document.querySelector("#balance");
  if (!balance) {
    console.error("Balance element not found!");
    return;
  }

  // Add event listener to the screen
  priceInput.addEventListener("input", (e) => {
    channel.push("price_input_change", {
      value: e.target.value,
      balance: balance.innerText,
    });
  });

  console.log("Price input change tracking setup complete.");
}

export function handlePriceInputChange(payload) {
  const { value } = payload;
  console.log(`Input change, value - ${value}`)

  const priceInput = document.querySelector("#price-input")
  if (!priceInput) {
    console.error("Price input element not found!");
    return;
  }

  priceInput.value = value;
}
