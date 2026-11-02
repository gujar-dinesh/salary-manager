import { MantineProvider } from '@mantine/core'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render } from '@testing-library/react'
import type { ReactNode } from 'react'
import { MemoryRouter } from 'react-router-dom'
import { vi } from 'vitest'

export function renderWithProviders(ui: ReactNode, { route = '/' } = {}) {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } })

  return render(
    <QueryClientProvider client={queryClient}>
      <MantineProvider env="test">
        <MemoryRouter initialEntries={[route]}>{ui}</MemoryRouter>
      </MantineProvider>
    </QueryClientProvider>,
  )
}

export function mockFetch(routes: Record<string, unknown>) {
  const fetchMock = vi.fn(async (url: string) => {
    const path = Object.keys(routes)
      .sort((a, b) => b.length - a.length)
      .find((key) => url.startsWith(key))
    if (!path) return new Response('{}', { status: 404 })
    return new Response(JSON.stringify(routes[path]), { status: 200 })
  })
  vi.stubGlobal('fetch', fetchMock)
  return fetchMock
}
