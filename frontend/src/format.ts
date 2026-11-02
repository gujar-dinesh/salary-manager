export function formatMoney(amount: number, currency: string) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    maximumFractionDigits: 0,
  }).format(amount)
}

export function formatEmploymentType(type: string) {
  return type.replace('_', ' ').replace(/^\w/, (c) => c.toUpperCase())
}
