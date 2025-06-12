export function handleOrderLog(payload) {
  const { timestamp, action, amount, username, btc_price } = payload;
  console.log(`Order log: ${action} $${amount} by ${username} at ${timestamp}`);

  const orderLog = document.querySelector("#order-log");
  if (!orderLog) {
    console.error("Order log element not found!");
    return;
  }

  const emptyOrderLog = document.querySelector("#empty-order-log");
  if (emptyOrderLog) {
    emptyOrderLog.remove();
  }

  // Create new order entry
  const orderEntry = document.createElement("div");
  orderEntry.className = "mb-1 p-1 border-b border-base-200";

  const timeStr = new Date(timestamp).toLocaleTimeString();
  const actionClass = action === "BUY" ? "text-green-600" : "text-red-600";

  orderEntry.innerHTML = `
    <span class="text-xs text-gray-500">${timeStr}</span>
    <span class="${actionClass} font-semibold">${action}</span>
    <span>$${amount}</span>
    <span class="text-xs">@ $${btc_price}</span>
    <span class="text-xs">by ${username}</span>
  `;

  // Add to top of log
  orderLog.insertBefore(orderEntry, orderLog.firstChild);

  // Keep only last 50 entries
  while (orderLog.children.length > 50) {
    orderLog.removeChild(orderLog.lastChild);
  }
}
