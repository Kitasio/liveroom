export function setupBalanceInputChangeTracking(channel) {
  const balanceInput = document.querySelector("#balance-input");
  if (!balanceInput) {
    console.error("Balance input element not found!");
    return;
  }

  // Add event listener to the screen
  balanceInput.addEventListener("input", (e) => {
    channel.push("balance_input_change", {
      balance: e.target.value,
    });
  });

  console.log("Balance input change tracking setup complete.");

  channel.on("balance_input_change", handleBalanceInputChange);
  channel.on("update_balance", handleBalanceUpdate);
}

export function handleBalanceInputChange(payload) {
  console.log(`Balance payload: ${JSON.stringify(payload)}`)
  const { balance } = payload;
  console.log(`Input change, balance - ${balance}`)

  const balanceEl = document.querySelector("#balance")
  if (!balanceEl) {
    console.error("Balance element not found!");
    return;
  }

  balanceEl.innerText = balance;
}

export function handleBalanceUpdate(payload) {
  const { balance } = payload;

  const balanceEl = document.querySelector("#balance")
  if (!balanceEl) {
    console.error("Balance element not found!");
    return;
  }

  balanceEl.innerText = balance;
}
