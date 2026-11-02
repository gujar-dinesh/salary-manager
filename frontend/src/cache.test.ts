import { QueryClient } from '@tanstack/react-query'
import { describe, expect, it } from 'vitest'
import { refreshEmployeeData } from './cache'

function seededClient() {
  const client = new QueryClient()
  for (const key of [['employees', {}], ['options'], ['insights', 'overview'], ['employee', 7]]) client.setQueryData(key, {})
  return client
}

describe('refreshEmployeeData', () => {
  it('marks every list, option and insight query as stale', () => {
    const client = seededClient()

    refreshEmployeeData(client)

    for (const key of [['employees', {}], ['options'], ['insights', 'overview']]) {
      expect(client.getQueryState(key)?.isInvalidated).toBe(true)
    }
  })

  it('forgets a deleted employee', () => {
    const client = seededClient()

    refreshEmployeeData(client, { deletedId: 7 })

    expect(client.getQueryData(['employee', 7])).toBeUndefined()
  })
})
