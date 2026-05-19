interface DataTableProps {
  columns: { key: string; label: string }[];
  data: any[];
}

export default function DataTable({ columns, data }: DataTableProps) {
  return (
    <div className="overflow-x-auto rounded-lg border border-gray-800">
      <table className="w-full text-sm text-left">
        <thead className="bg-[#1a1a1a] text-gray-400 uppercase text-xs">
          <tr>
            {columns.map((col) => (
              <th key={col.key} className="px-4 py-3 font-medium">
                {col.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.map((row, i) => (
            <tr
              key={i}
              className={`border-t border-gray-800 ${i % 2 === 0 ? 'bg-[#111]' : 'bg-[#0a0a0a]'}`}
            >
              {columns.map((col) => (
                <td key={col.key} className="px-4 py-2.5 text-gray-300">
                  {row[col.key] ?? '—'}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
