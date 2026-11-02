import { describe, expect, it } from 'vitest'
import { formatEmploymentType, formatMoney } from './format'

describe('formatMoney', () => {
  it('formats whole amounts with the currency symbol', () => {
    expect(formatMoney(1234567.4, 'USD')).toBe('$1,234,567')
    expect(formatMoney(5000, 'EUR')).toBe('€5,000')
  })
})

describe('formatEmploymentType', () => {
  it('turns the stored value into a label', () => {
    expect(formatEmploymentType('full_time')).toBe('Full time')
    expect(formatEmploymentType('contractor')).toBe('Contractor')
  })
})
