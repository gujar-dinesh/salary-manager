import type { QueryClient } from '@tanstack/react-query'

// Lists, filter options and insights all depend on employee data, so any write refreshes them.
export function refreshEmployeeData(queryClient: QueryClient, { deletedId }: { deletedId?: number } = {}) {
  if (deletedId !== undefined) queryClient.removeQueries({ queryKey: ['employee', deletedId] })
  queryClient.invalidateQueries({ queryKey: ['employees'] })
  queryClient.invalidateQueries({ queryKey: ['options'] })
  queryClient.invalidateQueries({ queryKey: ['insights'] })
}
