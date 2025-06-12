export function setupBuyButtonTracking(channel) {
  const buyBtn = document.querySelector("#buy-btn");
  if (!buyBtn) {
    console.error("Buy button element not found!");
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

  buyBtn.addEventListener("click", (e) => {
    const livePriceEl = document.querySelector("#live-price");
    const currentPrice = livePriceEl ? livePriceEl.innerText.replace('$', '').replace(',', '') : "0";

    channel.push("buy_order", {
      amount: priceInput.value,
      balance: balance.innerText,
      btc_price: currentPrice
    });
  });

  console.log("Buy button tracking setup complete.");
}
