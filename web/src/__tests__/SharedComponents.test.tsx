import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { TagInput } from '@/components/shared/TagInput'
import { ConfirmDialog } from '@/components/shared/ConfirmDialog'
import { DataTable } from '@/components/shared/DataTable'
import type { ColumnDef } from '@tanstack/react-table'

describe('TagInput', () => {
  const onChange = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders existing tags as badges', () => {
    render(<TagInput value={['foo', 'bar']} onChange={onChange} />)
    expect(screen.getByText('foo')).toBeInTheDocument()
    expect(screen.getByText('bar')).toBeInTheDocument()
  })

  it('Enter adds new tag', () => {
    render(<TagInput value={['existing']} onChange={onChange} />)
    const input = screen.getByRole('textbox')
    fireEvent.change(input, { target: { value: 'newtag' } })
    fireEvent.keyDown(input, { key: 'Enter' })
    expect(onChange).toHaveBeenCalledWith(['existing', 'newtag'])
  })

  it('X button removes tag', () => {
    render(<TagInput value={['alpha', 'beta']} onChange={onChange} />)
    // Each tag has a remove button with an X icon
    const removeButtons = screen.getAllByRole('button')
    fireEvent.click(removeButtons[0])
    expect(onChange).toHaveBeenCalledWith(['beta'])
  })

  it('Backspace on empty input removes last tag', () => {
    render(<TagInput value={['one', 'two', 'three']} onChange={onChange} />)
    const input = screen.getByRole('textbox')
    fireEvent.keyDown(input, { key: 'Backspace' })
    expect(onChange).toHaveBeenCalledWith(['one', 'two'])
  })
})

describe('ConfirmDialog', () => {
  const onConfirm = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders trigger and shows title on open', async () => {
    render(
      <ConfirmDialog
        trigger={<button>Open</button>}
        title="Are you sure?"
        description="This action cannot be undone."
        onConfirm={onConfirm}
        confirmLabel="Yes, delete"
      />
    )
    expect(screen.getByText('Open')).toBeInTheDocument()
    fireEvent.click(screen.getByText('Open'))
    // Dialog content should appear
    expect(await screen.findByText('Are you sure?')).toBeInTheDocument()
    expect(screen.getByText('This action cannot be undone.')).toBeInTheDocument()
    expect(screen.getByText('Yes, delete')).toBeInTheDocument()
    expect(screen.getByText('Cancel')).toBeInTheDocument()
  })

  it('confirm calls onConfirm', async () => {
    render(
      <ConfirmDialog
        trigger={<button>Open</button>}
        title="Confirm?"
        description="Proceed?"
        onConfirm={onConfirm}
        confirmLabel="OK"
      />
    )
    fireEvent.click(screen.getByText('Open'))
    const okButton = await screen.findByText('OK')
    fireEvent.click(okButton)
    expect(onConfirm).toHaveBeenCalledTimes(1)
  })

  it('cancel closes dialog', async () => {
    render(
      <ConfirmDialog
        trigger={<button>Open</button>}
        title="Confirm?"
        description="Really?"
        onConfirm={onConfirm}
      />
    )
    fireEvent.click(screen.getByText('Open'))
    const cancelBtn = await screen.findByText('Cancel')
    fireEvent.click(cancelBtn)
    // Title should no longer be visible after cancel
    // (Give time for animation / close)
    await vi.waitFor(() => {
      expect(screen.queryByText('Really?')).not.toBeInTheDocument()
    })
  })
})

describe('DataTable', () => {
  interface Row {
    id: number
    name: string
    age: number
  }

  const data: Row[] = [
    { id: 1, name: 'Alice', age: 30 },
    { id: 2, name: 'Bob', age: 25 },
    { id: 3, name: 'Charlie', age: 35 },
  ]

  const columns: ColumnDef<Row>[] = [
    { accessorKey: 'name', header: 'Name' },
    { accessorKey: 'age', header: 'Age' },
  ]

  it('renders columns and rows', () => {
    render(<DataTable columns={columns} data={data} />)
    expect(screen.getByText('Name')).toBeInTheDocument()
    expect(screen.getByText('Age')).toBeInTheDocument()
    expect(screen.getByText('Alice')).toBeInTheDocument()
    expect(screen.getByText('Bob')).toBeInTheDocument()
    expect(screen.getByText('Charlie')).toBeInTheDocument()
    expect(screen.getByText('30')).toBeInTheDocument()
  })

  it('sorting toggles on header click', async () => {
    render(<DataTable columns={columns} data={data} />)

    // Find the sortable header button for "Name"
    const nameHeader = screen.getByRole('button', { name: /Sort by Name/i })
    expect(nameHeader).toBeInTheDocument()

    // Click to sort ascending
    fireEvent.click(nameHeader)

    // First row should be Alice (ascending)
    const rows = screen.getAllByRole('row')
    // Row 0 is header, rows 1-3 are data
    expect(rows[1]).toHaveTextContent('Alice')

    // Click again to sort descending
    fireEvent.click(nameHeader)

    const rowsAfter = screen.getAllByRole('row')
    expect(rowsAfter[1]).toHaveTextContent('Charlie')
  })
})
