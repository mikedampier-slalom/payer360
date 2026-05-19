interface KPICardProps {
  title: string;
  value: string | number | null | undefined;
  subtitle?: string;
  isLoading?: boolean;
  tooltip?: string;
}

export default function KPICard({ title, value, subtitle, isLoading, tooltip }: KPICardProps) {
  return (
    <div className="rounded-xl border border-white/10 bg-white/5 p-4 flex flex-col gap-1" title={tooltip}>
      <span className="text-xs text-gray-400 uppercase tracking-wide">{title}</span>
      {isLoading ? (
        <div className="h-8 w-24 bg-white/10 animate-pulse rounded" />
      ) : (
        <span className="text-2xl font-bold text-white">{value ?? '—'}</span>
      )}
      {subtitle && <span className="text-xs text-gray-500">{subtitle}</span>}
    </div>
  );
}
