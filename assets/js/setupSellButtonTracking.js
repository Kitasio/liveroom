export function setupSellButtonTracking(channel) {
  const sellBtn = document.querySelector("#sell-btn");
  if (!sellBtn) {
    console.error("Sell button element not found!");
    return;
  }

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

  sellBtn.addEventListener("click", (e) => {
    const livePriceEl = document.querySelector("#live-price");
    const currentPrice = livePriceEl ? livePriceEl.innerText.replace('$', '').replace(',', '') : "0";

    channel.push("sell_order", {
      amount: priceInput.value,
      balance: balance.innerText,
      btc_price: currentPrice
    });
  });

  console.log("Sell button tracking setup complete.");
}
