import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { Download } from 'lucide-react'
import Papa from 'papaparse'
import { jsPDF } from 'jspdf'

interface VisitRow {
  poi_name: string
  latitude: number
  longitude: number
  visited_at: string
  visited_time?: string
  poi_type: string
}

interface VisitExportProps {
  visits: VisitRow[]
}

type PageFormat = 'a4' | 'letter'

interface PdfField {
  key: 'date' | 'time' | 'notes' | 'gps'
  label: string
  default: boolean
}

export function VisitExport({ visits }: VisitExportProps) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const [showPdfOptions, setShowPdfOptions] = useState(false)
  const [pageFormat, setPageFormat] = useState<PageFormat>('a4')
  const [pdfFields, setPdfFields] = useState<Record<string, boolean>>({
    date: true,
    time: false,
    notes: false,
    gps: false,
  })

  const PDF_FIELDS: PdfField[] = [
    { key: 'date', label: t('user.history.fieldDate'), default: true },
    { key: 'time', label: t('user.history.fieldTime'), default: false },
    { key: 'notes', label: t('user.history.fieldNotes'), default: false },
    { key: 'gps', label: t('user.history.fieldGps'), default: false },
  ]

  function exportCSV() {
    const csv = Papa.unparse(visits.map(v => ({
      [t('user.dashboard.stats.csvHeaders.place')]: v.poi_name,
      [t('user.dashboard.stats.csvHeaders.latitude')]: v.latitude,
      [t('user.dashboard.stats.csvHeaders.longitude')]: v.longitude,
      [t('user.dashboard.stats.csvHeaders.date')]: v.visited_at,
      [t('user.dashboard.stats.csvHeaders.type')]: v.poi_type,
    })))
    downloadFile(csv, 'visits.csv', 'text/csv')
    setOpen(false)
  }

  function exportJSON() {
    const json = JSON.stringify(visits, null, 2)
    downloadFile(json, 'visits.json', 'application/json')
    setOpen(false)
  }

  function exportPDF() {
    const doc = new jsPDF({ format: pageFormat })
    doc.setFontSize(16)
    doc.text(t('user.dashboard.stats.pdfTitle'), 14, 20)
    doc.setFontSize(10)
    let y = 35
    const maxY = pageFormat === 'a4' ? 280 : 270

    visits.forEach((v, i) => {
      if (y > maxY) { doc.addPage(); y = 20 }

      let line = `${i + 1}. ${v.poi_name}`
      if (pdfFields.date) line += ` — ${v.visited_at}`
      if (pdfFields.time && v.visited_time) line += ` ${v.visited_time}`
      line += ` (${v.poi_type})`
      if (pdfFields.gps) line += ` [${v.latitude.toFixed(5)}, ${v.longitude.toFixed(5)}]`

      doc.text(line, 14, y)
      y += 7
    })
    doc.save('visits.pdf')
    setShowPdfOptions(false)
    setOpen(false)
  }

  function toggleField(key: string) {
    setPdfFields(prev => ({ ...prev, [key]: !prev[key] }))
  }

  function downloadFile(content: string, filename: string, mimeType: string) {
    const blob = new Blob([content], { type: mimeType })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = filename
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="relative">
      <Button variant="outline" size="sm" onClick={() => { setOpen(!open); setShowPdfOptions(false) }}>
        <Download className="h-4 w-4 mr-1" />
        {t('user.dashboard.stats.exportBtn')}
      </Button>
      {open && (
        <div className="absolute top-full left-0 mt-1 bg-background border rounded-md shadow-md z-10 py-1 min-w-[120px]">
          <button onClick={exportCSV} className="w-full px-4 py-1.5 text-sm text-left hover:bg-muted">
            {t('user.dashboard.stats.exportFormats.csv')}
          </button>
          <button onClick={exportJSON} className="w-full px-4 py-1.5 text-sm text-left hover:bg-muted">
            {t('user.dashboard.stats.exportFormats.json')}
          </button>
          <button
            onClick={() => setShowPdfOptions(!showPdfOptions)}
            className="w-full px-4 py-1.5 text-sm text-left hover:bg-muted"
          >
            {t('user.dashboard.stats.exportFormats.pdf')}
          </button>
          {showPdfOptions && (
            <div className="border-t px-4 py-3 space-y-3">
              <div>
                <p className="text-xs font-medium mb-1">{t('user.history.pageFormat')}</p>
                <div className="flex gap-2">
                  {(['a4', 'letter'] as PageFormat[]).map(fmt => (
                    <button
                      key={fmt}
                      onClick={() => setPageFormat(fmt)}
                      className={`rounded px-2 py-0.5 text-xs border ${
                        pageFormat === fmt ? 'bg-primary text-white border-primary' : 'border-input hover:bg-muted'
                      }`}
                    >
                      {fmt.toUpperCase()}
                    </button>
                  ))}
                </div>
              </div>
              <div>
                <p className="text-xs font-medium mb-1">{t('user.history.selectFields')}</p>
                <div className="space-y-1">
                  {PDF_FIELDS.map(field => (
                    <label key={field.key} className="flex items-center gap-2 text-xs">
                      <input
                        type="checkbox"
                        checked={pdfFields[field.key]}
                        onChange={() => toggleField(field.key)}
                        className="rounded"
                      />
                      {field.label}
                    </label>
                  ))}
                </div>
              </div>
              <Button size="sm" onClick={exportPDF} className="w-full">
                {t('common.export')}
              </Button>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
