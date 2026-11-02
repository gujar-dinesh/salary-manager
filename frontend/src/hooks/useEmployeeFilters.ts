import { useDebouncedValue } from '@mantine/hooks'
import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'

const PER_PAGE = 25

export type SortColumn = 'full_name' | 'salary' | 'hire_date'
export type FilterKey = 'country' | 'department' | 'job_title'

// Filters live in the URL so they survive navigation and reloads.
export function useEmployeeFilters() {
  const [params, setParams] = useSearchParams()
  const [search, setSearchInput] = useState(params.get('q') ?? '')
  const [debouncedSearch] = useDebouncedValue(search, 300)

  const filters = {
    q: debouncedSearch,
    country: params.get('country') ?? '',
    department: params.get('department') ?? '',
    job_title: params.get('job_title') ?? '',
    sort: (params.get('sort') ?? 'full_name') as SortColumn,
    direction: params.get('direction') === 'desc' ? 'desc' : 'asc',
    page: Number(params.get('page') ?? 1),
    per_page: PER_PAGE,
  }

  const update = (changes: Record<string, string | null>, resetPage = true) => {
    const next = new URLSearchParams(params)
    Object.entries(changes).forEach(([key, value]) => (value ? next.set(key, value) : next.delete(key)))
    if (resetPage) next.delete('page')
    setParams(next)
  }

  return {
    filters,
    search,
    setSearch: (value: string) => {
      setSearchInput(value)
      update({ q: value })
    },
    setFilter: (key: FilterKey, value: string | null) => update({ [key]: value }),
    setPage: (page: number) => update({ page: String(page) }, false),
    toggleSort: (column: SortColumn) => {
      const direction = filters.sort === column && filters.direction === 'asc' ? 'desc' : 'asc'
      update({ sort: column, direction })
    },
  }
}
